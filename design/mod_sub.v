`timescale 1ns / 1ps

module mod_sub #(
    parameter WIDTH = 32
  ) (
    input wire  [WIDTH-1:0] A,
    input wire  [WIDTH-1:0] B,
    input wire  [WIDTH-1:0] modulus,
    output wire [WIDTH-1:0] C
    );
    
    wire signed   [WIDTH:0] diff;
    wire          [WIDTH:0] diff_mod;
    
    assign diff = A - B;
    assign diff_mod = diff + modulus;
    assign C = (diff < 0) ? diff_mod : diff;
   
endmodule
