`timescale 1ns / 1ps


module hweval_circular_shift #(
    parameter WIDTH = 32,
    parameter SIZE = 257
) ( 
  input wire clk,
  input wire [SIZE*WIDTH-1:0] in_list, // 257 32-bit values
  input wire [8:0] in_shift, // Shift amount
  output wire [SIZE*WIDTH-1:0] out_list // Circularly shifted list
); 
  // Define signals
  reg [WIDTH*SIZE-1:0]  input_list;
  reg [8:0]             shift_amount;
  wire [WIDTH*SIZE-1:0] shifted_list;
  
  always @(posedge clk) begin
    input_list <= in_list;
    shift_amount <= in_shift;
  end
  
  circular_shift #(
    .SIZE   (SIZE   ),
    .WIDTH  (WIDTH  )
  ) dut (
    .input_list     (input_list     ),
    .shift_amount   (shift_amount   ),
    .shifted_list   (shifted_list   )
  );
  
  reg [WIDTH*SIZE-1:0] out_reg;
  always @(posedge clk) begin
    out_reg <= shifted_list;
  end
        
  assign out_list = out_reg;
    
endmodule