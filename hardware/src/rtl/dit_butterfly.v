`timescale 1ns / 1ps
`include "defines.v"

module dit_butterfly # (
    parameter WIDTH = 32
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             mode,  // 0 = butterfly, 1 = multiply
    input  wire             swap,  // multiply A, instead of B
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    input  wire [WIDTH-1:0] W,
    input  wire [WIDTH-1:0] modulus,
    output wire [WIDTH-1:0] A_out,
    output wire [WIDTH-1:0] B_out
    );
    
    localparam MODMUL_DELAY = `INTMUL_DELAY + `MODRED_DELAY + 1;
       
    wire [WIDTH-1:0] A_delayed;
    
    delay_n_cycles #(
        .N(MODMUL_DELAY),
        .WIDTH(WIDTH)
    ) D (
        .clk(clk),
        .reset(reset),
        .data_in(mode ? 'd0 : A),
        .data_out(A_delayed)
    );
    
    wire [WIDTH-1:0] BxW;
    wire [WIDTH-1:0] mult_in;
    assign mult_in = (mode && swap) ? A : B;
    
    ModMult mod_mult (
    .clk    (clk      ),
    .reset  (reset    ),
    .A      (mult_in  ),
    .B      (W        ),
    .q      (modulus  ),
    .C      (BxW      ) 
    );
    
    reg  [WIDTH-1:0] reg_BxW;
    
    always @(posedge clk) begin
        reg_BxW <= BxW;
    end
    
    mod_add #(.WIDTH(WIDTH)) add (
    .A       (A_delayed                ),
    .B       (reg_BxW                  ),
    .modulus (modulus                  ),
    .C       (A_out                    )
    );
    
    mod_sub #(.WIDTH(WIDTH)) sub (
    .A       (A_delayed                ),
    .B       (reg_BxW                  ),
    .modulus (modulus                  ),
    .C       (B_out                    )
    );
        
endmodule
