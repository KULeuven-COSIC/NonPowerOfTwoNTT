`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_memory;

  // Define parameters and signals
  parameter N = 257;
  reg clk = 0;
  reg [N-1:0] we;
  reg [N*8-1:0] addr;
  reg [N*32-1:0] din;
  wire [N*32-1:0] dout;

  // Instantiate the memory module
  memory #(.N(N)) dut (
    .clk(clk),
    .we(we),
    .addr(addr),
    .din(din),
    .dout(dout)
  );

  // Clock generator
  initial begin
    forever #`CLK_HALF clk = ~clk;
  end
  
  // Stimulus
  initial begin
    // Write to memory
    we = {1'b1, {(N-1){1'b1}}};
    addr = {N{8'd0}};
    din = {32'h12345678, 32'hDEAF, {(N-3){32'h0}}, 32'hABCDEF};
    #`CLK_PERIOD;
    we = 'b0;
    #`CLK_PERIOD;

    // Read from memory
    we = 'b0;
    addr = {N{8'd0}};
    #`CLK_PERIOD;
    $display("dout = %h", dout);
    $finish;
  end

endmodule
