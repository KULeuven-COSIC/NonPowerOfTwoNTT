`timescale 1ns / 1ps

`include "defines.v"

module ntt #(
    parameter WIDTH = 32,
    parameter SIZE = 257  
)(
    input  wire                    clk,           // Clock signal
    input  wire                    reset,         // Reset signal
    input  wire                    start,         // Start signal
    input  wire   [5:0]            mod_idx,       // Modular index
    input  wire                    mem_read,      // Memory read enable
    input  wire                    mem_write,     // Memory write enable
    input  wire   [8*SIZE-1:0]     mem_addr,      // Memory address bus
    input  wire   [WIDTH*SIZE-1:0] din,           // Data input bus
    output wire   [WIDTH*SIZE-1:0] dout,          // Data output bus
    output wire                    done           // Done signal
    );
    
    // Define parameters
    localparam MODMUL_DELAY = (`MODRED_DELAY + `INTMUL_DELAY + 1 + 1);
    localparam MEM_DELAY = 2;
    localparam PIPELINE_DELAY = (MODMUL_DELAY + MEM_DELAY + 2) + 1 + 1 + 1;
    localparam BUTTERFLY_UNITS = 128;
    localparam N_ADDERS = 51;

    localparam N_MODULI = 40; // Number of elements in the MODULI array
    reg [31:0] moduli[0:N_MODULI-1];
    
    initial begin
        $readmemh("moduli.mem", moduli);
    end
    
    genvar i;
    
    // Control signals
    wire [8:0]             cs1_shift;
    wire [8:0]             cs2_shift;
    wire [SIZE*8-1:0]      addr_read;
    wire [SIZE*8-1:0]      addr_write;
    wire [SIZE-1:0]        we;
    wire [2:0]             rpp_op;
    wire [2:0]             brp_op;
    wire                   bfa_mode;
    wire                   bfa_swap;
    wire [10:0]            bfa_w_idx;
    wire [2:0]             merge_sel;
    wire [2:0]             add_b_in_sel;
    
    wire [8:0]             cs2_shift_D;
    wire [2:0]             rpp_op_D;
    wire [2:0]             brp_op_D;
    wire                   bfa_mode_D;
    wire                   bfa_swap_D;
    wire [10:0]            bfa_w_idx_D;
    
    wire [2:0]             merge_sel_D;
    wire [2:0]             add_b_in_sel_D;
    wire [8:0]             cs1_shift_D;
    wire [SIZE*8-1:0]      addr_write_D;
    wire [SIZE-1:0]        we_D;
    
    // Delay control signals for pipeline operation
    delay_fifo #(
        .DELAY(MEM_DELAY),
        .WIDTH(9)
    ) inst_delay_ctrl_1 (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    (cs2_shift),
        .data_out   (cs2_shift_D)
    );
    
    delay_fifo #(
        .DELAY(MEM_DELAY + 1),
        .WIDTH(3)
    ) inst_delay_ctrl_1_1 (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    (rpp_op),
        .data_out   (rpp_op_D)
    );
    
    delay_fifo #(
        .DELAY(MEM_DELAY + 2),
        .WIDTH(3)
    ) inst_delay_ctrl_2 (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    (brp_op),
        .data_out   (brp_op_D)
    );
    
    delay_fifo #(
        .DELAY(MEM_DELAY + 3),
        .WIDTH(2)
    ) inst_delay_ctrl_2_1 (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    ({bfa_mode, bfa_swap}),
        .data_out   ({bfa_mode_D, bfa_swap_D})
    );
    
    delay_fifo #(
        .DELAY(MEM_DELAY),
        .WIDTH(11)
    ) inst_delay_ctrl_3 (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    (bfa_w_idx),
        .data_out   (bfa_w_idx_D)
    );
    
    delay_fifo #(
        .DELAY(PIPELINE_DELAY - 2),
        .WIDTH(6)
    ) inst_delay_ctrl_4 (
        .clk        (clk                          ),
        .reset      (1'b0                         ),
        .data_in    ({merge_sel, add_b_in_sel}    ),
        .data_out   ({merge_sel_D, add_b_in_sel_D})
    );
    
    delay_fifo #(
        .DELAY(PIPELINE_DELAY - 1),
        .WIDTH(9)
    ) inst_delay_ctrl_5 (
        .clk        (clk         ),
        .reset      (1'b0        ),
        .data_in    (cs1_shift   ),
        .data_out   (cs1_shift_D )
    );
    
    delay_fifo #(
        .DELAY(PIPELINE_DELAY),
        .WIDTH(8*SIZE)
    ) inst_delay_addr (
        .clk        (clk           ),
        .reset      (reset         ),
        .data_in    (addr_write    ),
        .data_out   (addr_write_D  )
    );
    
    delay_fifo #(
        .DELAY(PIPELINE_DELAY),
        .WIDTH(SIZE)
    ) inst_delay_we (
        .clk        (clk            ),
        .reset      (reset          ),
        .data_in    (we             ),
        .data_out   (we_D           )
    );
    
    // Controller instantiation
    controller #(
        .PIPELINE_DELAY(PIPELINE_DELAY)
    ) inst_controller (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mod_idx(mod_idx),
        .cs1_shift(cs1_shift),
        .cs2_shift(cs2_shift),
        .addr_read(addr_read),
        .addr_write(addr_write),
        .we(we),
        .rpp_op(rpp_op),
        .brp_op(brp_op),
        .bfa_mode(bfa_mode),
        .bfa_swap(bfa_swap),
        .bfa_w_idx(bfa_w_idx),
        .merge_sel(merge_sel),
        .add_b_in_sel(add_b_in_sel),
        .done(done)
    );    
    
    // Circular shift block at memory input
    wire [WIDTH*SIZE-1:0] cs1_in, cs1_out;
    circular_shift #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) inst_circular_shift_1 (
        .input_list     (cs1_in         ),
        .shift_amount   (cs1_shift_D    ),
        .shifted_list   (cs1_out        )
    );
    
    reg [WIDTH*SIZE-1:0] cs1_out_D;
    always @(posedge clk) begin
        cs1_out_D <= cs1_out;
    end
    
    
    wire [SIZE*WIDTH-1:0] mem_in, mem_out;
    assign mem_in = mem_write ? din : cs1_out_D;
    
    memory #(
        .N(SIZE)
    ) inst_memory (
        .clk        (clk         ),
        .we         (mem_write ? {SIZE{1'b1}} : we_D    ),
        .addr_write (mem_write ? mem_addr : addr_write_D),
        .addr_read  (mem_read  ? mem_addr : addr_read   ),
        .din        (mem_in      ),
        .dout       (mem_out     )
    );
    
    assign dout   = mem_out;
      
    // Circular shift block at memory output
    wire [WIDTH*SIZE-1:0] cs2_out;
    circular_shift #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) inst_circular_shift_2 (
        .input_list     (mem_out        ),
        .shift_amount   (cs2_shift_D    ),
        .shifted_list   (cs2_out        )
    );
    
    // Add pipeline register
    reg [WIDTH*SIZE-1:0] cs2_out_D;
    always @(posedge clk) begin
        cs2_out_D <= cs2_out;
    end
    
    wire [SIZE*WIDTH-1:0] rpp_in, rpp_out;
    
    assign rpp_in = cs2_out_D;
    
    // Merged permutation block for rader / pfa / bit reverse permutations
    merged_permutation #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) inst_merged_permutation (
        .input_list     (rpp_in        ),
        .perm_select    (rpp_op_D      ),
        .output_list    (rpp_out       )
    );
    
    wire [(SIZE-1)*WIDTH-1:0] brp_in, brp_out;
    
    // Add pipeline register
    reg [SIZE*WIDTH-1:0] rpp_out_D;
    always @(posedge clk) begin
        rpp_out_D <= rpp_out;
    end
    
    assign brp_in = rpp_out_D[(SIZE-1)*WIDTH - 1 : 0];
    
    // Bit reversal block
    bit_reversal #(
        .SIZE(SIZE-1),
        .WIDTH(WIDTH)
    ) inst_bit_reversal (
        .input_list     (brp_in         ),
        .step           (brp_op_D       ),
        .output_list    (brp_out        )
    );
    
    // add pipeline register
    reg [(SIZE - 1)*WIDTH-1:0] brp_out_D;
    always @(posedge clk) begin
        brp_out_D <= brp_out;
    end
    
    
    wire [BUTTERFLY_UNITS*WIDTH - 1 : 0] bfa_a_in, bfa_b_in, bfa_a_out, bfa_b_out, bfa_a_in_D;
    wire [(SIZE-1)*WIDTH - 1 : 0] bfa_out, mult_out;
    
    // Separate even and uneven indices for butterfly input
    generate
    for (i = 0; i < BUTTERFLY_UNITS; i = i + 1) begin
        assign bfa_a_in[(i+1)*WIDTH - 1 -: WIDTH] = brp_out_D[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign bfa_b_in[(i+1)*WIDTH - 1 -: WIDTH] = brp_out_D[(2*i+2)*WIDTH - 1 -: WIDTH];
    end
    endgenerate
    
    reg [WIDTH-1:0] modulus;
    always @(posedge clk) begin
        if (start)
            modulus <= moduli[mod_idx];
        else
            modulus <= modulus;
    end
    
    // 128 dit-butterfly units
    butterfly_array inst_butterfly_array (
        .clk     (clk        ),
        .mode    (bfa_mode_D ),
        .swap    (bfa_swap_D ),
        .A       (bfa_a_in   ),
        .B       (bfa_b_in   ),
        .w_idx   (bfa_w_idx_D),
        .modulus (modulus    ),
        .A_out   (bfa_a_out  ),
        .B_out   (bfa_b_out  )
    );
    
    // Add pipeline register stage
    reg [BUTTERFLY_UNITS*WIDTH - 1 : 0] bfa_a_out_D;
    always @(posedge clk) begin
        bfa_a_out_D <= bfa_a_out;
    end
    
    // Combine separated results again
    generate
    for (i = 0; i < BUTTERFLY_UNITS; i = i + 1) begin
        assign bfa_out[(2*i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign bfa_out[(2*i+2)*WIDTH - 1 -: WIDTH] = bfa_b_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign mult_out[(2*i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign mult_out[(2*i+2)*WIDTH - 1 -: WIDTH] = bfa_a_out_D[(i+1)*WIDTH - 1 -: WIDTH];
    end
    endgenerate

    wire [WIDTH*N_ADDERS - 1 : 0] first_points;
    wire [WIDTH*N_ADDERS - 1 : 0] first_points_D;
    wire [WIDTH*N_ADDERS-1:0] second_points [0:6];
    
    // First points are placed at the end by merged permutation block in reversed order
    generate
        for (i = 0; i < N_ADDERS; i = i + 1) begin
            assign first_points[(i+1)*WIDTH-1 -: WIDTH] = rpp_out_D[WIDTH*(SIZE-i) - 1 -: WIDTH];
        end
    endgenerate
    
    // Delay for adder input
    delay_fifo #(
        .DELAY(MODMUL_DELAY + 1),
        .WIDTH(WIDTH*N_ADDERS)
    ) inst_delay_first_points (
        .clk(clk                  ),
        .reset(1'b0               ),
        .data_in(first_points     ),
        .data_out(first_points_D  )
    );
    
    delay_fifo #(
        .DELAY(MODMUL_DELAY),
        .WIDTH(128*WIDTH)
    ) inst_delay_bfa_a_in (
        .clk(clk                  ),
        .reset(1'b0               ),
        .data_in(bfa_a_in         ),
        .data_out(bfa_a_in_D      )
    );
            
    // Collect second points of each NTT sequence
    generate
    assign second_points[0][WIDTH-1 : 0] = bfa_a_out[WIDTH-1 : 0];
    assign second_points[4][WIDTH-1 : 0] = bfa_a_in_D[WIDTH-1 : 0];
    for (i = 0; i < N_ADDERS; i = i + 1) begin    
        if (i > 0) begin
            assign second_points[0][(i+1)*WIDTH - 1 -: WIDTH] = 'b0;
            assign second_points[4][(i+1)*WIDTH - 1 -: WIDTH] = 'b0;
        end
        if (i < 5*3) begin
            assign second_points[1][(i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(8*i+1)*WIDTH - 1 -: WIDTH];
            assign second_points[5][(i+1)*WIDTH - 1 -: WIDTH] = bfa_a_in_D[(8*i+1)*WIDTH - 1 -: WIDTH];
        end else begin
            assign second_points[1][(i+1)*WIDTH - 1 -: WIDTH] = 'b0;
            assign second_points[5][(i+1)*WIDTH - 1 -: WIDTH] = 'b0;
        end
        assign second_points[2][(i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign second_points[6][(i+1)*WIDTH - 1 -: WIDTH] = bfa_a_in_D[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign second_points[3][(i+1)*WIDTH - 1 -: WIDTH] = 'b0;
    end
    endgenerate
    
    wire [N_ADDERS*WIDTH-1:0] second_points_to_adders;
    assign second_points_to_adders = second_points[add_b_in_sel_D];
    
    wire [N_ADDERS*WIDTH-1:0] adders_to_merger;
    
    // Adders for performing additions required by Rader's algorithm
    adders #(
        .WIDTH(WIDTH),
        .N_ADDERS(N_ADDERS)
    ) inst_adders (
        .in_first_points  (first_points_D         ),
        .in_second_points (second_points_to_adders),
        .modulus          (modulus                ),
        .out_adder_result (adders_to_merger       )
    );
           
    wire [SIZE*WIDTH-1:0] merger_out;
    
    // Merger block for combining outputs from different modules / operations
    merger #(
        .WIDTH(WIDTH),
        .SIZE(SIZE),
        .N_ADDERS(N_ADDERS) 
    ) inst_merger (
        .clk(clk),
        .bfa_out(bfa_out),
        .mult_out(mult_out),
        .adder_result(adders_to_merger),
        .merge_sel(merge_sel_D),
        .output_list(merger_out)
    );
    
    // Add pipeline register stage
    reg [SIZE*WIDTH - 1 : 0] merged_result_D;
    always @(posedge clk) begin
        merged_result_D <= merger_out;
    end
        
    assign cs1_in = merged_result_D;
endmodule
