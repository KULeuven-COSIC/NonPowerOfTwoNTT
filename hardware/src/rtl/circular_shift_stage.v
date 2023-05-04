`timescale 1ns / 1ps


module circular_shift_stage
#(  
    parameter SIZE = 257,
    parameter WIDTH = 32,
    parameter SHIFT = 0
 )
 (
    input wire shift,
    input wire [SIZE*WIDTH-1:0] input_list,
    output reg [SIZE*WIDTH-1:0] shifted_list
 );
    
    always @(*) begin
        if (shift) begin
            shifted_list[SIZE*WIDTH-1 : SHIFT*WIDTH] = input_list[(SIZE-SHIFT)*WIDTH-1 : 0];
            shifted_list[SHIFT*WIDTH-1 : 0] = input_list[SIZE*WIDTH-1 : (SIZE-SHIFT)*WIDTH];
        end else begin
            shifted_list = input_list;
        end
    end
     
 endmodule
