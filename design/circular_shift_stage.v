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
