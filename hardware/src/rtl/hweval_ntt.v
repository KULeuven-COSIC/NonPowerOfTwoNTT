`timescale 1ns / 1ps

module hweval_ntt(
  input wire clk,
  input wire reset,
  input wire start_in,
  input wire [5:0] mod_idx_in,
  input wire mem_read_in,
  input wire mem_write_in,
  input wire [7:0] mem_addr_in,
  input wire [31:0]  din_in,
  output wire [31:0] dout_out,
  output wire done_out
    );
    

  wire [32*257-1:0] dout;
  reg [32*257-1:0] dout_reg;
  reg done_reg;
  
  reg start;
  reg [5:0] mod_idx;
  reg mem_read;
  reg mem_write;
  reg [8*257-1:0] mem_addr;
  reg [32*257-1:0] din;
  
  always @(posedge clk) begin
    start <= start_in;
    mod_idx <= mod_idx_in;
    mem_read <= mem_read_in;
    mem_write <= mem_write_in;
    mem_addr <= {mem_addr[8*256-1:0], mem_addr_in};
    din <= {din[32*256-1:0], din_in};
  end
    
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
  
  always @(posedge clk) begin
    if (done) begin
        dout_reg <= dout;
    end else begin
        dout_reg <= {32'b0, dout_reg[32*257-1:32]};
    end
    done_reg <= done; 
  end
  
  assign dout_out = dout_reg;
  assign done_out = done_reg;
  
endmodule
