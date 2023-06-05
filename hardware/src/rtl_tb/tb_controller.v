`timescale 1ns / 1ps

`include "defines.v"

module tb_controller;
  // Declare signals for the testbench
  reg clk;
  reg reset;
  reg start;
  reg [5:0] mod_idx;
  wire [8:0] cs1_shift;
  wire [8:0] cs2_shift;
  wire [257*8-1:0] addr_read;
  wire [257*8-1:0] addr_write;
  wire [256:0] we;
  wire [1:0] rpp_op;
  wire [2:0] brp_op;
  wire bfa_mode;
  wire bfa_swap;
  wire [10:0] bfa_w_idx;
  wire [2:0] merge_sel;
  wire [1:0] add_b_in_sel;
  wire done;

  // Instantiate the controller module
  controller dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .mod_idx(mod_idx),
    .cs1_shift(cs1_shift),
    .cs2_shift(cs2_shift),
    .addr_read(addr_read),
    .addr_write(addr_write),
    .we(we),
    .rpp_op(rpp_op),
    .brp_op(brp_op),
    .bfa_mode(bfa_mode),
    .bfa_swap(bfa_swap),
    .bfa_w_idx(bfa_w_idx),
    .merge_sel(merge_sel),
    .add_b_in_sel(add_b_in_sel),
    .done(done)
  );

  // Generate clock signal
  always #5 clk = ~clk;

  // Initialize signals
  initial begin
    clk = 0;
    reset = 1;
    start = 0;
    mod_idx = 0;

    // Wait for a few clock cycles
    #10 reset = 0;
    #10 
    mod_idx = 6'd1;
    start = 1;
    
    #10
    start = 0;

    // Wait for simulation to finish
    #56900 $finish;
  end

  // Monitor the output signals
  always @(posedge clk) begin
    $display("cs1_shift: %b", cs1_shift);
    $display("cs2_shift: %b", cs2_shift);
    $display("addr_read: %b", addr_read);
    $display("addr_write: %b", addr_write);
    $display("we: %b", we);
    $display("rpp_op: %b", rpp_op);
    $display("brp_op: %b", brp_op);
    $display("bfa_mode: %b", bfa_mode);
    $display("bfa_swap: %b", bfa_swap);
    $display("bfa_w_idx: %b", bfa_w_idx);
    $display("merge_sel: %b", merge_sel);
    $display("add_b_in_sel: %b", add_b_in_sel);
  end
endmodule
