`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_memory;

  // Define parameters and signals
  parameter N = 5;
  reg clk = 0;
  reg [N-1:0] we;
  reg [N*8-1:0] addr_write;
  reg [N*8-1:0] addr_read;
  reg [N*32-1:0] din;
  wire [N*32-1:0] dout;

  // Instantiate the memory module
  memory #(.N(N)) dut (
    .clk(clk),
    .we(we),
    .addr_write(addr_write),
    .addr_read(addr_read),
    .din(din),
    .dout(dout)
  );

  // Clock generator
  initial begin
    forever #`CLK_HALF clk = ~clk;
  end
  
  // Stimulus
  initial begin
  
    @(posedge clk);
    we = 0;
    addr_write = 0;
    addr_read = 0;
    din = 0;
    
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    
    // Write to memory
    we = 5'b11111;
    addr_write = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4};
    addr_read = {8'd4, 8'd4, 8'd4, 8'd4, 8'd4}; //{8'd1, 8'd2, 8'd3, 8'd4, 8'd5};
    din = {32'h12345678, 32'hDEAF, {(N-3){32'h0}}, 32'hABCDEF};
    #`CLK_PERIOD;
    
    // Read from memory
    we = 5'b00000;
    addr_write = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
    addr_read = {8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
    #`CLK_PERIOD;
    we = 5'b11111;
    $display("dout = %h", dout);
    #`CLK_PERIOD;
    we = 5'b11111;
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    $finish;
  end

endmodule
