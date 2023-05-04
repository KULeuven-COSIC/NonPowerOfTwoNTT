`timescale 1ns / 1ps
`include "defines.v"

module dit_butterfly # (
    parameter WIDTH = 32
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             mode,  // 0 = butterfly, 1 = multiply B
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    input  wire [WIDTH-1:0] W,
    input  wire [WIDTH-1:0] modulus,
    output wire [WIDTH-1:0] A_out,
    output wire [WIDTH-1:0] B_out
    );
    
    localparam MODMUL_DELAY = `INTMUL_DELAY + `MODRED_DELAY + 1;
    
    reg [WIDTH-1:0] shift_reg [0:MODMUL_DELAY-1]; // Declare a shift register of length multiplier delay
    
    always @(posedge clk) begin : shift_logic
        integer i;
        if (reset) begin // reset
            for (i = 0; i < MODMUL_DELAY; i=i+1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            for (i = 0; i < MODMUL_DELAY; i=i+1) begin // Shift the data to the right
                shift_reg[i] <= shift_reg[i-1];
            end
                shift_reg[0] <= mode ? 'd0 : A; // Input new data at the left end
        end
    end
    
    wire [WIDTH-1:0] BxW;
    
    ModMult mod_mult (
    .clk    (clk      ),
    .reset  (reset    ),
    .A      (B        ),
    .B      (W        ),
    .q      (modulus  ),
    .C      (BxW      ) 
    );
    
    reg  [WIDTH-1:0] reg_BxW;
    
    always @(posedge clk) begin
        reg_BxW <= BxW;
    end
    
    wire signed   [WIDTH:0] diff, sum_mod;
    wire          [WIDTH:0] sum, diff_mod;
    
    assign sum  = shift_reg[MODMUL_DELAY-1] + reg_BxW;
    assign diff = shift_reg[MODMUL_DELAY-1] - reg_BxW;
    
    assign sum_mod  = sum  - modulus;
    assign diff_mod = diff + modulus;
    
    assign A_out = (sum_mod < 0) ? sum : sum_mod;
    assign B_out = (diff < 0) ? diff_mod : diff;
    
endmodule
