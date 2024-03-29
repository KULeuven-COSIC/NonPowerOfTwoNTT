`timescale 1ns / 1ps

`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_ntt;

  reg clk;
  reg reset;
  reg start;
  reg [5:0] mod_idx;
  reg mem_read;
  reg mem_write;
  reg [8*257-1:0] mem_addr;
  reg [32*257-1:0] din;
  wire [32*257-1:0] dout;
  wire done; 
   
  // Instantiate the NTT module
  ntt dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .mod_idx(mod_idx),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_addr(mem_addr),
    .din(din),
    .dout(dout),
    .done(done)
  );

  // Create a 85x257 memory
  reg [31:0] data [0:85*257-1];

  // Load memory data from .mem file
  integer file;
  integer col;
  integer row;
  integer error_count;
  integer i;
  reg [31:0] expected_result [0:85*257-1];
  
  initial begin
    
    #`CLK_PERIOD; // Wait for some time
    // Setup
    reset = 1; // Assert reset
    clk = 0;
    start = 0;
    mod_idx = 1;
    mem_read = 0;
    mem_write = 0;
    mem_addr = 0;
    din = 0;
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    reset = 0;
    #`CLK_PERIOD;
    
    // Initialize memory
    $readmemh("memory_data.mem", data);
    #`CLK_PERIOD;
    // Write each row of memory to the NTT module
    for (row = 0; row < 85; row = row + 1) begin
      mem_addr = {257{row[7:0]}}; // Set the memory address
      for (col = 0; col < 257; col = col + 1) begin
          din[(col+1)*32-1 -: 32] = data[257 * row + col];
      end

      // Assert mem_write for one clock cycle to write the row
      mem_write = 1;
      #`CLK_PERIOD;
    end
    mem_write = 0;
    #`CLK_PERIOD;
    
    // Perform NTT
    start = 1;
    #`CLK_PERIOD;
    start = 0;
    #`CLK_PERIOD;
    @(posedge done);
    #`CLK_PERIOD;
    
    // Read out memory
    mem_read = 1;
    for (row = 0; row < 85; row = row + 1) begin
      mem_addr = {257{row[7:0]}}; // Set the memory address
      #`CLK_PERIOD;
      #`CLK_PERIOD;
      for (col = 0; col < 257; col = col + 1) begin
          data[257 * row + col] = dout[(col+1)*32-1 -: 32];
      end
    end
    #`CLK_PERIOD;
    
    // Store result in file
    $writememh("ntt_result.mem", data);
    #`CLK_PERIOD;
    
    // Check result
    $readmemh("expected_result.mem", expected_result);
    #`CLK_PERIOD;
    // Comparison loop
    error_count = 0;
    for (i = 0; i < 85*257; i = i + 1) begin
      if (data[i] !== expected_result[i]) begin
        $display("Mismatch at index %d: Expected %h, got %h", i, expected_result[i], data[i]);
        error_count = error_count + 1;
      end
    end
    $display("Total: %d Errors", error_count);
    $display("Result stored in ntt_result.mem");
    
    $finish; // End simulation
  end

  always begin
    #`CLK_HALF;
    clk = ~clk;
  end

endmodule
