`timescale 1ns / 1ps

`include "defines.v"

module ntt #(
    parameter WIDTH = 32,
    parameter SIZE = 257  
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    start,
    input  wire   [5:0]            mod_idx,
    input  wire                    mem_read,
    input  wire                    mem_write,
    input  wire   [8*SIZE-1:0]     mem_addr,
    input  wire   [WIDTH*SIZE-1:0] din,
    output wire   [WIDTH*SIZE-1:0] dout,
    output wire                    done
    );
    
    // Define parameters
    localparam MODMUL_DELAY = (`MODRED_DELAY + `INTMUL_DELAY + 1);
    localparam MEM_DELAY = 2;
    localparam PIPELINE_DELAY = (MODMUL_DELAY + MEM_DELAY + 2);
    localparam BUTTERFLY_UNITS = 128;
    localparam MAX_PARALLEL_NTTS = 17;
    localparam MODULI = {32'd4244570881, 32'd4043247361, 32'd3909031681, 32'd3690931201, 32'd3623823361, 32'd3556715521, 32'd3523161601, 32'd3506384641, 32'd3439276801, 32'd3422499841, 32'd3204399361, 32'd3187622401, 32'd3154068481, 32'd3086960641, 32'd2952744961, 32'd2734644481, 32'd2516544001, 32'd2466213121, 32'd2415882241, 32'd2382328321, 32'd2365551361, 32'd2164227841, 32'd2130673921, 32'd2097120001, 32'd1862242561, 32'd1711249921, 32'd1644142081, 32'd1627365121, 32'd1593811201, 32'd1577034241, 32'd1509926401, 32'd1358933761, 32'd1275048961, 32'd1157610241, 32'd1107279361, 32'd838848001, 32'd721409281, 32'd654301441, 32'd419424001, 32'd335539201};
    
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
    
    delay_n_cycles #(
        .N(MEM_DELAY),
        .WIDTH(12)
    ) D1_ctrl_inst (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    ({cs2_shift, rpp_op}),
        .data_out   ({cs2_shift_D, rpp_op_D})
    );
    
    delay_n_cycles #(
        .N(MEM_DELAY + 1),
        .WIDTH(5)
    ) D2_ctrl_inst (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    ({brp_op, bfa_mode, bfa_swap}),
        .data_out   ({brp_op_D, bfa_mode_D, bfa_swap_D})
    );
    
    delay_n_cycles #(
        .N(MEM_DELAY),
        .WIDTH(11)
    ) D25_ctrl_inst (
        .clk        (clk),
        .reset      (1'b0),
        .data_in    (bfa_w_idx),
        .data_out   (bfa_w_idx_D)
    );
    
    delay_n_cycles #(
        .N(PIPELINE_DELAY - 1),
        .WIDTH(6)
    ) D3_ctrl_inst (
        .clk        (clk                                        ),
        .reset      (1'b0                                       ),
        .data_in    ({merge_sel, add_b_in_sel}       ),
        .data_out   ({merge_sel_D, add_b_in_sel_D} )
    );
    
    delay_n_cycles #(
        .N(PIPELINE_DELAY),
        .WIDTH(9)
    ) D4_ctrl_inst (
        .clk        (clk                                        ),
        .reset      (1'b0                                       ),
        .data_in    (cs1_shift   ),
        .data_out   (cs1_shift_D )
    );
    
    
    
    delay_n_cycles #(
        .N(PIPELINE_DELAY),
        .WIDTH(8*SIZE)
    ) D_addr_inst (
        .clk        (clk           ),
        .reset      (reset         ),
        .data_in    (addr_write    ),
        .data_out   (addr_write_D  )
    );
    
    delay_n_cycles #(
        .N(PIPELINE_DELAY),
        .WIDTH(SIZE)
    ) D_we_inst (
        .clk        (clk            ),
        .reset      (reset          ),
        .data_in    (we             ),
        .data_out   (we_D           )
    );
    
    controller #(
        .PIPELINE_DELAY(PIPELINE_DELAY)
    ) ctrl (
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
    
    wire [WIDTH*SIZE-1:0] cs1_in, cs1_out;
    circular_shift #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) cs1 (
        .input_list     (cs1_in         ),
        .shift_amount   (cs1_shift_D    ),
        .shifted_list   (cs1_out        )
    );
    
    wire [SIZE*WIDTH-1:0] mem_in, mem_out;
    
    assign mem_in = mem_write ? din : cs1_out;
    
    memory #(
        .N(SIZE)
    ) mem (
        .clk        (clk         ),
        .we         (mem_write ? {SIZE{1'b1}} : we_D    ),
        .addr_write (mem_write ? mem_addr : addr_write_D),
        .addr_read  (mem_read  ? mem_addr : addr_read   ),
        .din        (mem_in      ),
        .dout       (mem_out     )
    );
    
    wire [WIDTH*SIZE-1:0] cs2_in, cs2_out;
        
    assign cs2_in = mem_out;
    assign dout   = mem_out;
    
    circular_shift #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) cs2 (
        .input_list     (cs2_in         ),
        .shift_amount   (cs2_shift_D    ),
        .shifted_list   (cs2_out        )
    );
    
    wire [SIZE*WIDTH-1:0] rpp_in, rpp_out;
    reg [SIZE*WIDTH-1:0] rpp_out_D;
    
    assign rpp_in = cs2_out;
    
    merged_permutation #(
        .SIZE(SIZE),
        .WIDTH(WIDTH)
    ) rpp (
        .input_list     (rpp_in        ),
        .perm_select    (rpp_op_D      ),
        .output_list    (rpp_out       )
    );
    
    wire [(SIZE-1)*WIDTH-1:0] brp_in, brp_out;
    
    always @(posedge clk) begin
        rpp_out_D <= rpp_out;
    end
    
    assign brp_in = rpp_out_D[(SIZE-1)*WIDTH - 1 : 0];
    
    bit_reversal #(
        .SIZE(SIZE-1),
        .WIDTH(WIDTH)
    ) brp (
        .input_list     (brp_in         ),
        .step           (brp_op_D       ),
        .output_list    (brp_out        )
    );
    
    
    wire [BUTTERFLY_UNITS*WIDTH - 1 : 0] bfa_a_in, bfa_b_in, bfa_a_out, bfa_b_out, bfa_a_out_D, bfa_a_in_D;
    wire [(SIZE-1)*WIDTH - 1 : 0] bfa_out, mult_out;
    
    generate
    for (i = 0; i < BUTTERFLY_UNITS; i = i + 1) begin
        assign bfa_a_in[(i+1)*WIDTH - 1 -: WIDTH] = brp_out[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign bfa_b_in[(i+1)*WIDTH - 1 -: WIDTH] = brp_out[(2*i+2)*WIDTH - 1 -: WIDTH];
    end
    endgenerate
    
    reg [WIDTH-1:0] modulus;
    always @(posedge clk) begin
        if (start)
            modulus <= MODULI[(mod_idx + 1) * WIDTH - 1 -: WIDTH];
        else
            modulus <= modulus;
    end
    
    butterfly_array bfa (
        .clk     (clk        ),
        .reset   (reset      ),
        .mode    (bfa_mode_D ),
        .swap    (bfa_swap_D ),
        .A       (bfa_a_in   ),
        .B       (bfa_b_in   ),
        .w_idx   (bfa_w_idx_D),
        .modulus (modulus    ),
        .A_out   (bfa_a_out  ),
        .B_out   (bfa_b_out  )
    );
    
    delay_n_cycles #(
        .N(1),
        .WIDTH(BUTTERFLY_UNITS*WIDTH)
    ) bfa_D (
        .clk(clk                  ),
        .reset(1'b0               ),
        .data_in(bfa_a_out        ),
        .data_out(bfa_a_out_D     )
    );
    
    generate
    for (i = 0; i < BUTTERFLY_UNITS; i = i + 1) begin
        assign bfa_out[(2*i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign bfa_out[(2*i+2)*WIDTH - 1 -: WIDTH] = bfa_b_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign mult_out[(2*i+1)*WIDTH - 1 -: WIDTH] = bfa_a_out[(i+1)*WIDTH - 1 -: WIDTH];
        assign mult_out[(2*i+2)*WIDTH - 1 -: WIDTH] = bfa_a_out_D[(i+1)*WIDTH - 1 -: WIDTH];
    end
    endgenerate

    wire [WIDTH*MAX_PARALLEL_NTTS - 1 : 0] first_points;
    wire [WIDTH*MAX_PARALLEL_NTTS - 1 : 0] first_points_D;
    wire [WIDTH-1:0] second_points [0:6][0:MAX_PARALLEL_NTTS-1];
    
    generate
        for (i = 0; i < 17; i = i + 1) begin
            assign first_points[(i+1)*WIDTH-1 -: WIDTH] = rpp_out_D[WIDTH*(SIZE-i) - 1 -: WIDTH];
        end
    endgenerate
    
    delay_n_cycles #(
        .N(MODMUL_DELAY),
        .WIDTH(WIDTH*MAX_PARALLEL_NTTS)
    ) delay_inst (
        .clk(clk                  ),
        .reset(1'b0               ),
        .data_in(first_points     ),
        .data_out(first_points_D  )
    );
    
    delay_n_cycles #(
        .N(MODMUL_DELAY),
        .WIDTH(128*WIDTH)
    ) D13221 (
        .clk(clk                  ),
        .reset(1'b0               ),
        .data_in(bfa_a_in         ),
        .data_out(bfa_a_in_D      )
    );
            
    // Collect second points of each NTT sequence
    generate
    assign second_points[0][0] = bfa_a_out[WIDTH-1 : 0];
    assign second_points[4][0] = bfa_a_in_D[WIDTH-1 : 0];
    for (i = 0; i < MAX_PARALLEL_NTTS; i = i + 1) begin    
        if (i > 0) begin
            assign second_points[0][i] = 'b0;
            assign second_points[4][i] = 'b0;
        end
        if (i < 5) begin
            assign second_points[1][4-i] = bfa_a_out[(8*i+1)*WIDTH - 1 -: WIDTH];
            assign second_points[5][4-i] = bfa_a_in_D[(8*i+1)*WIDTH - 1 -: WIDTH];
        end else begin
            assign second_points[1][i] = 'b0;
            assign second_points[5][i] = 'b0;
        end
        assign second_points[2][16-i] = bfa_a_out[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign second_points[6][16-i] = bfa_a_in_D[(2*i+1)*WIDTH - 1 -: WIDTH];
        assign second_points[3][i] = 'b0;
    end
    endgenerate
    
    
    wire [WIDTH-1:0] adder_result   [0:MAX_PARALLEL_NTTS-1];
    wire [WIDTH-1:0] adder_result_D [0:MAX_PARALLEL_NTTS-1];
        
    generate
    for (i = 0; i < MAX_PARALLEL_NTTS; i = i + 1) begin : adders
        mod_add #(.WIDTH(WIDTH)) add (
            .A       (first_points_D[(i+1)*WIDTH - 1 -: WIDTH] ),
            .B       (second_points[add_b_in_sel_D][i]   ),
            .modulus (modulus                            ),
            .C       (adder_result[i]                    )
        );
        delay_n_cycles #(
            .N(1),
            .WIDTH(WIDTH)
        ) add_D (
            .clk        (clk               ),
            .reset      (1'b0              ),
            .data_in    (adder_result[i]   ),
            .data_out   (adder_result_D[i] )
        );
    end
    endgenerate
    
    reg [SIZE*WIDTH - 1 : 0] merged_result, merged_result_D;
       
    always @(*) begin : merge
        integer i;
        // default
        merged_result[SIZE*WIDTH - 1 -: 256*WIDTH]     = bfa_out;
        merged_result[WIDTH - 1 : 0]                   = adder_result[0];
        case (merge_sel_D)
            3'd0: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH] = bfa_out;
                merged_result[WIDTH - 1 : 0]               = adder_result[0];
            end
            3'd1: begin
                for (i = 0; i < 5; i = i + 1) begin
                    merged_result[(17*i+17)*WIDTH - 1 -:16*WIDTH] = bfa_out[(16*i+16)*WIDTH - 1 -:16*WIDTH];
                    merged_result[(17*i+1)*WIDTH - 1 -:WIDTH]     = adder_result[4-i];
                end
            end
            3'd2: begin
                for (i = 0; i < 17; i = i + 1) begin
                    merged_result[(5*i+5)*WIDTH - 1 -:4*WIDTH] = bfa_out[(4*i+4)*WIDTH - 1 -:4*WIDTH];
                    merged_result[(5*i+1)*WIDTH - 1 -:WIDTH] = adder_result[16-i];
                end
            end
            3'd4: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH]     = mult_out;
                merged_result[2*WIDTH - 1 -: WIDTH]            = adder_result[0];
                merged_result[WIDTH - 1 : 0]                   = adder_result_D[0];
            end
            3'd5: begin
                for (i = 0; i < 5; i = i + 1) begin
                    merged_result[(17*i+17)*WIDTH - 1 -:16*WIDTH] = mult_out[(16*i+16)*WIDTH - 1 -:16*WIDTH];
                    merged_result[(17*i+2)*WIDTH - 1 -:WIDTH]     = adder_result[4-i];
                    merged_result[(17*i+1)*WIDTH - 1 -:WIDTH]     = adder_result_D[4-i];
                end
            end
            3'd6: begin
                for (i = 0; i < 17; i = i + 1) begin
                    merged_result[(5*i+5)*WIDTH - 1 -:4*WIDTH] = mult_out[(4*i+4)*WIDTH - 1 -:4*WIDTH];
                    merged_result[(5*i+2)*WIDTH - 1 -:WIDTH] = adder_result[16-i];
                    merged_result[(5*i+1)*WIDTH - 1 -:WIDTH] = adder_result_D[16-i];
                end
            end
            default: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH]     = bfa_out;
                merged_result[WIDTH - 1 : 0]                   = adder_result[0];
            end
        endcase
    end
    
    always @(posedge clk) begin
        merged_result_D <= merged_result;
    end
        
    assign cs1_in = merged_result_D;
endmodule
