`timescale 1ns / 1ps

// Define parameters

module hweval_bit_reversal ( 
  input wire clk,
  input wire [SIZE*WIDTH-1:0] in_list, // 257 32-bit values
  input wire [7:0] in_perm, // Shift amount
  output wire [SIZE*WIDTH-1:0] out_list // Circularly shifted list
);
  localparam WIDTH = 32;
  localparam SIZE = 256;
  
  // Define signals
  reg [WIDTH*SIZE-1:0]  input_list;
  reg [7:0]             perm_enable;
  wire [WIDTH*SIZE-1:0] output_list;
  
  always @(posedge clk) begin
    input_list <= in_list;
    perm_enable <= in_perm;
  end
  
  bit_reversal #(
    .SIZE   (SIZE   ),
    .WIDTH  (WIDTH  )
  ) dut (
    .input_list     (input_list     ),
    .perm_enable    (perm_enable    ),
    .output_list    (output_list   )
  );
  
  reg [WIDTH*SIZE-1:0] out_reg;
  always @(posedge clk) begin
    out_reg <= output_list;
  end
        
  assign out_list = out_reg;
    
endmodule