`timescale 1ns / 1ps

// Define parameters

module hweval_merged_permutation # (
  parameter WIDTH = 32,
  parameter SIZE = 257
) ( 
  input wire clk,
  input wire [SIZE*WIDTH-1:0] in_list,
  input wire [1:0] in_perm,
  output wire [SIZE*WIDTH-1:0] out_list
);
  // Define signals
  reg [WIDTH*SIZE-1:0]  input_list;
  reg [1:0]             perm_select;
  wire [WIDTH*SIZE-1:0] output_list;
  
  always @(posedge clk) begin
    input_list <= in_list;
    perm_select <= in_perm;
  end
  
  merged_permutation #(
    .SIZE   (SIZE   ),
    .WIDTH  (WIDTH  )
  ) dut (
    .input_list     (input_list     ),
    .perm_select    (perm_select    ),
    .output_list    (output_list   )
  );
  
  reg [WIDTH*SIZE-1:0] out_reg;
  always @(posedge clk) begin
    out_reg <= output_list;
  end
        
  assign out_list = out_reg;
    
endmodule