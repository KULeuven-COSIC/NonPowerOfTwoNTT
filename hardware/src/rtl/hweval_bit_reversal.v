`timescale 1ns / 1ps

// Define parameters

module hweval_bit_reversal 
#(
  parameter WIDTH = 32,
  parameter SIZE = 257 
)
( 
  input wire clk,
  input wire [SIZE*WIDTH-1:0] in_list, // 257 32-bit values
  input wire [2:0] in_step, // Shift amount
  output wire [SIZE*WIDTH-1:0] out_list // Circularly shifted list
);
  // Define signals
  reg [WIDTH*SIZE-1:0]  input_list;
  reg [7:0]             step;
  wire [WIDTH*SIZE-1:0] output_list;
  
  always @(posedge clk) begin
    input_list <= in_list;
    step       <= in_step;
  end
  
  bit_reversal #(
    .SIZE   (SIZE   ),
    .WIDTH  (WIDTH  )
  ) dut (
    .input_list     (input_list     ),
    .step           (step           ),
    .output_list    (output_list    )
  );
  
  reg [WIDTH*SIZE-1:0] out_reg;
  always @(posedge clk) begin
    out_reg <= output_list;
  end
        
  assign out_list = out_reg;
    
endmodule