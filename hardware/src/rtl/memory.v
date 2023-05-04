`timescale 1ns / 1ps


module memory #
  (parameter N = 257)
  (input wire clk,
   input wire [N-1:0] we,
   input wire [N-1:0][7:0] addr,
   input wire [N-1:0][31:0] din,
   output wire [N-1:0][31:0] dout
  );

  wire [31:0] dout_i [0:N-1];
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : blk_mem
      blk_mem_gen_0 blk_mem_inst (
        .clka(clk),
        .wea(we[i]),
        .addra(addr[i]),
        .dina(din[i]),
        .clkb(clk),
        .addrb(addr[i]),
        .doutb(dout_i[i])
      );
      assign dout[i] = dout_i[i];
    end
  endgenerate

endmodule