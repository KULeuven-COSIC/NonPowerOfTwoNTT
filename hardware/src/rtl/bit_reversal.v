`timescale 1ns / 1ps

module bit_reversal_stage
#(  
    parameter SIZE = 256,
    parameter WIDTH = 32,
    parameter DEPTH = 0
 )
 (
    input wire enable,
    input wire [SIZE-1:0][WIDTH-1:0] input_list,
    output wire [SIZE-1:0][WIDTH-1:0] output_list
 );
    
    genvar i;
    generate
    for (i = 0; i < 256; i = i + 1) begin
        assign output_list[i] = enable ? input_list[reverse_bits(i, DEPTH)] : input_list[i];
    end
    endgenerate
    
    function [7:0] reverse_bits;
        input [7:0] in_bits;
        input [3:0] depth;
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                if (i <= depth)
                    reverse_bits[i] = in_bits[depth - i];
                else
                    reverse_bits[i] = in_bits[i];
            end
        end
    endfunction 
       
 endmodule
 

module bit_reversal #(  
    parameter SIZE = 256,
    parameter WIDTH = 32
 ) (   
  input wire [SIZE-1:0][WIDTH-1:0] input_list, // 256 32-bit values
  input wire [7:0] perm_enable,
  output wire [SIZE-1:0][WIDTH-1:0] output_list
);  
  
  wire [SIZE*WIDTH-1:0] bit_rev_stage [0:7];
  
  assign bit_rev_stage[0] = input_list;
  
  genvar i;
  generate
    for (i = 1; i < 8; i = i + 1) begin : rev_stg
      bit_reversal_stage #(
        .DEPTH(i)
      ) bit_reversal_stage_inst (
        .enable         (perm_enable[i]     ),
        .input_list     (bit_rev_stage[i-1] ),
        .output_list    (bit_rev_stage[i]   )
      );
    end
  endgenerate
  
  assign output_list = bit_rev_stage[7];
  
endmodule