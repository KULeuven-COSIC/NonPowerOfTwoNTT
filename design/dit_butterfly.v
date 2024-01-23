`timescale 1ns / 1ps
`include "defines.v"

module dit_butterfly # (
    parameter WIDTH = 32
)(
    input  wire             clk,
    input  wire             mode,  // 0 = butterfly, 1 = multiply
    input  wire             swap,  // multiply A, instead of B
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    input  wire [WIDTH-1:0] W,
    input  wire [WIDTH-1:0] modulus,
    output reg  [WIDTH-1:0] A_out,
    output reg  [WIDTH-1:0] B_out
    );
    
    localparam MODMUL_DELAY = `INTMUL_DELAY + `MODRED_DELAY + 1;
       
    wire [WIDTH-1:0] A_delayed;
    
    delay_fifo #(
        .DELAY(MODMUL_DELAY),
        .WIDTH(WIDTH)
    ) inst_delay_A (
        .clk(clk),
        .reset(1'b0),
        .data_in(mode ? 'd0 : A),
        .data_out(A_delayed)
    );
    
    wire [WIDTH-1:0] BxW;
    wire [WIDTH-1:0] mult_in;
    assign mult_in = (mode && swap) ? A : B;
    
    ModMult inst_mod_mult (
    .clk    (clk      ),
    .A      (mult_in  ),
    .B      (W        ),
    .q      (modulus  ),
    .C      (BxW      ) 
    );
    
    reg  [WIDTH-1:0] reg_BxW;
    
    always @(posedge clk) begin
        reg_BxW <= BxW;
    end
    
    wire [WIDTH-1:0] add_out, sub_out;
    
    mod_add #(.WIDTH(WIDTH)) inst_add (
    .A       (A_delayed                ),
    .B       (reg_BxW                  ),
    .modulus (modulus                  ),
    .C       (add_out                  )
    );
    
    mod_sub #(.WIDTH(WIDTH)) inst_sub (
    .A       (A_delayed                ),
    .B       (reg_BxW                  ),
    .modulus (modulus                  ),
    .C       (sub_out                  )
    );
    
    always @(posedge clk) begin
        A_out <= add_out;
        B_out <= sub_out;
    end
        
endmodule
