`timescale 1ns / 1ps


module mem_control(
        input  wire                 clk,
        input  wire                 reset,
        input  wire                 soft_reset,
        input  wire [1:0]           stage,
        input  wire                 incr,
        output wire [257*8-1:0]     addr,
        output wire [256:0]         we,
        output wire [8:0]           cs1_shift,
        output wire [8:0]           cs2_shift
    );
    
    localparam SIZE  = 257;
    localparam DEPTH = 85;
    localparam SHIFT = 3*85;
       
    wire mode;
    assign mode = (stage == 2'd0) ? 0 : 1;
    
    address_generator addr_gen_inst (
        .clk        (clk                  ),
        .reset      (reset || soft_reset  ),
        .mode       (mode                 ),
        .incr       (incr                 ),
        .addr       (addr                 )
    );
    
    // shift update logic
    localparam SHIFT_M0 = 1;
    localparam SHIFT_M1 = 3*85;
     
    reg [8:0] reg_cs1_shift;
    reg [8:0] reg_cs2_shift;
    wire [8:0] next_shift_m0;
    wire [8:0] next_shift_m1;  
    wire [8:0] next_shift;
       
    mod_sub #(.WIDTH(9)) shift_cs2_sub (
        .A(reg_cs2_shift),
        .B(SHIFT_M0[8:0]),
        .modulus(SIZE[8:0]),
        .C(next_shift_m0)
    );
    
    mod_add #(.WIDTH(9)) shift_cs2_add (
        .A(reg_cs2_shift),
        .B(SHIFT_M1[8:0]),
        .modulus(SIZE[8:0]),
        .C(next_shift_m1)
    );
    
    assign next_shift = mode ? next_shift_m1 : next_shift_m0;
    
    always @(posedge clk) begin
        if (reset || soft_reset) begin
            reg_cs2_shift <= 'd0;
            reg_cs1_shift <= 'd0;
        end else if (incr) begin
            reg_cs2_shift <= next_shift;
            reg_cs1_shift <= (next_shift == 0) ? 0 : (SIZE - next_shift);
        end else begin
            reg_cs2_shift <= reg_cs2_shift;
            reg_cs1_shift <= reg_cs1_shift;
        end
    end
    
    assign cs1_shift = reg_cs1_shift;
    assign cs2_shift = reg_cs2_shift;
    
    // write enable logic
    reg [SIZE-1:0] reg_we;
    
    always @(posedge clk) begin
        if (reset || soft_reset) begin
            reg_we <= {2'b0, {255{1'b1}}};
        end else if (incr) begin
            reg_we <= {reg_we[SHIFT - 1 : 0], reg_we[SIZE - 1 -: SIZE - SHIFT]};
        end else begin
            reg_we <= reg_we;
        end
    end
        
    assign we = mode ? reg_we : {257{1'b1}};
    
endmodule
