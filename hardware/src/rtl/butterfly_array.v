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
    
    reg [WIDTH-1:0] w_lut [0:SIZE-1][0:LUT_SIZE-1];
    
    initial begin : init_table  
      $readmemh("twiddle_factor_tables.mem", w_lut);
    end
    
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : butterfly_unit
            
            wire [WIDTH-1:0] W;
            assign W = w_lut[i][w_idx];
                        
            dit_butterfly butterfly_inst (
                .clk     (clk      ),
                .reset   (reset    ),
                .mode    (mode     ),
                .swap    (swap     ),
                .A       (A[i]     ),
                .B       (B[i]     ),
                .W       (W        ),
                .modulus (modulus  ),
                .A_out   (A_out[i] ),
                .B_out   (B_out[i] )
            );
              
        end
    endgenerate
    
    

endmodule
