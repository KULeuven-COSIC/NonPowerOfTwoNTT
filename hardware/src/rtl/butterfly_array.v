`timescale 1ns / 1ps


module butterfly_array #(
    parameter WIDTH = 32,
    parameter SIZE = 128,
    parameter LUT_SIZE = 1360
) (
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        mode,  // 0 = butterfly, 1 = multiply
    input  wire                        swap,  // multiply A, instead of B
    input  wire [SIZE-1:0][WIDTH-1:0]  A,
    input  wire [SIZE-1:0][WIDTH-1:0]  B,
    input  wire [$clog2(LUT_SIZE)-1:0] w_idx,
    input  wire [WIDTH-1:0]            modulus,
    output wire [SIZE-1:0][WIDTH-1:0]  A_out,
    output wire [SIZE-1:0][WIDTH-1:0]  B_out
    );
    
    wire [4095:0] w_rom_out;
    twiddle_factor_rom w_lut (
      .clka(clk),    // input wire clka
      .addra(w_idx), // input wire [10 : 0] addra
      .douta(w_rom_out)  // output wire [4095 : 0] douta
    );
    
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : butterfly_unit
            
            wire [WIDTH-1:0] W;
            assign W = w_rom_out[(SIZE - i) * WIDTH - 1 -: WIDTH];
                        
            dit_butterfly butterfly_inst (
                .clk     (clk      ),
                .reset   (reset    ),
                .mode    (mode     ),
                .swap    (swap     ),
                .A       (A[i]     ),
                .B       (B[i]     ),
                .W       (W_rom    ),
                .modulus (modulus  ),
                .A_out   (A_out[i] ),
                .B_out   (B_out[i] )
            );
              
        end
    endgenerate
    
    

endmodule
