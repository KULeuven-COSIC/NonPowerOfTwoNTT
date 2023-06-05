`timescale 1ns / 1ps


module memory #
  (parameter N = 257)
  (input wire  clk,
   input wire  [N-1:0] we,
   input wire  [N-1:0][7:0] addr_write,
   input wire  [N-1:0][7:0] addr_read,
   input wire  [N-1:0][31:0] din,
   output wire [N-1:0][31:0] dout
  );

  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : blk_mem
      blk_mem_gen_0 blk_mem_inst (
        .clka(clk),
        .ena(we[i]),
        .wea(we[i]),
        .addra(addr_write[i]),
        .dina(din[i]),
        .clkb(clk),
        .addrb(addr_read[i]),
        .doutb(dout[i])
      );
    end
  endgenerate

endmodule