`timescale 1ns / 1ps

module mod_add #(
    parameter WIDTH = 32
  ) (
    input wire  [WIDTH-1:0] A,
    input wire  [WIDTH-1:0] B,
    input wire  [WIDTH-1:0] modulus,
    output wire [WIDTH-1:0] C
    );
      
    wire signed   [WIDTH:0] sum_mod;
    wire          [WIDTH:0] sum;
    
    assign sum  = A + B;
    assign sum_mod  = sum  - modulus;
    assign C = (sum_mod < 0) ? sum : sum_mod;
   
endmodule
