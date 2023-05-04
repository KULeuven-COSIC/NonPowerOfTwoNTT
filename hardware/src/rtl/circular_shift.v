`timescale 1ns / 1ps


module circular_shift_stage
#(  
    parameter SIZE = 257,
    parameter WIDTH = 32,
    parameter SHIFT = 0
 )
 (
    input wire shift,
    input wire [SIZE-1:0][WIDTH-1:0] input_list,
    output wire [SIZE-1:0][WIDTH-1:0] shifted_list
 );
    assign shifted_list[SIZE-1 : SHIFT] = shift ? input_list[SIZE-SHIFT-1 : 0] : input_list[SIZE-1 : SHIFT]; 
    assign shifted_list[SHIFT-1 : 0] = shift ? input_list[SIZE-1 : SIZE-SHIFT] : input_list[SHIFT-1 : 0];
 endmodule
 

module circular_shift #(  
    parameter SIZE = 257,
    parameter WIDTH = 32
 ) (   
  input wire [SIZE-1:0][WIDTH-1:0] input_list, // 257 32-bit values
  input wire [8:0] shift_amount, // Shift amount
  output wire [SIZE-1:0][WIDTH-1:0] shifted_list // Circularly shifted list
);  
  
  wire [SIZE*WIDTH-1:0] shift_stage [0:8];
  
  circular_shift_stage #(
    .SIZE(SIZE),
    .WIDTH(WIDTH),
    .SHIFT(1)
  ) circular_shift_stage_0 (
    .shift          (shift_amount[0]),
    .input_list     (input_list     ),
    .shifted_list   (shift_stage[0] )
  );
  
  genvar i;
  generate
    for (i = 1; i < 9; i = i + 1) begin : shift_stg
      circular_shift_stage #(
        .SIZE(SIZE),
        .SHIFT(1<<i)
      ) circular_shift_stage_inst (
        .shift          (shift_amount[i]    ),
        .input_list     (shift_stage[i-1]   ),
        .shifted_list   (shift_stage[i]     )
      );
    end
  endgenerate
  
  assign shifted_list = shift_stage[8];
endmodule