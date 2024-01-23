`timescale 1ns / 1ps

module merger #(
    parameter WIDTH = 32,
    parameter SIZE = 257,
    parameter N_ADDERS = 51 
) (
    input  wire                        clk,
    input  wire [(SIZE-1)*WIDTH - 1:0] bfa_out,
    input  wire [(SIZE-1)*WIDTH - 1:0] mult_out,
    input  wire [N_ADDERS*WIDTH-1:0]   adder_result,
    input  wire [2:0]                  merge_sel,
    output wire [SIZE*WIDTH-1:0]       output_list
    );
    
    reg [SIZE*WIDTH-1:0] merged_result;
    assign output_list = merged_result;
    
    reg [N_ADDERS*WIDTH-1:0] adder_result_previous;
    always @(posedge clk) begin
        adder_result_previous <= adder_result;
    end
    
    always @(*) begin : merger
        integer i;
        case (merge_sel)
            3'd0: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH] = bfa_out;
                merged_result[WIDTH - 1 : 0]               = adder_result[WIDTH-1:0];
            end
            3'd1: begin
                for (i = 0; i < 3*5; i = i + 1) begin
                    merged_result[(17*i+17)*WIDTH - 1 -:16*WIDTH] = bfa_out[(16*i+16)*WIDTH - 1 -:16*WIDTH];
                    merged_result[(17*i+1)*WIDTH - 1 -:WIDTH]     = adder_result[(i+1)*WIDTH-1 -: WIDTH];
                end
            end
            3'd2: begin
                for (i = 0; i < 3*17; i = i + 1) begin
                    merged_result[(5*i+5)*WIDTH - 1 -:4*WIDTH] = bfa_out[(4*i+4)*WIDTH - 1 -:4*WIDTH];
                    merged_result[(5*i+1)*WIDTH - 1 -:WIDTH] = adder_result[(i+1)*WIDTH-1 -: WIDTH];
                end
            end
            3'd4: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH]     = mult_out;
                merged_result[2*WIDTH - 1 -: WIDTH]            = adder_result[WIDTH-1 : 0];
                merged_result[WIDTH - 1 : 0]                   = adder_result_previous[WIDTH-1 : 0];
            end
            3'd5: begin
                for (i = 0; i < 3*5; i = i + 1) begin
                    merged_result[(17*i+17)*WIDTH - 1 -:16*WIDTH] = mult_out[(16*i+16)*WIDTH - 1 -:16*WIDTH];
                    merged_result[(17*i+2)*WIDTH - 1 -:WIDTH]     = adder_result[(i+1)*WIDTH-1 -: WIDTH];
                    merged_result[(17*i+1)*WIDTH - 1 -:WIDTH]     = adder_result_previous[(i+1)*WIDTH-1 -: WIDTH];
                end
            end
            3'd6: begin
                for (i = 0; i < 3*17; i = i + 1) begin
                    merged_result[(5*i+5)*WIDTH - 1 -:4*WIDTH] = mult_out[(4*i+4)*WIDTH - 1 -:4*WIDTH];
                    merged_result[(5*i+2)*WIDTH - 1 -:WIDTH] = adder_result[(i+1)*WIDTH-1 -: WIDTH];
                    merged_result[(5*i+1)*WIDTH - 1 -:WIDTH] = adder_result_previous[(i+1)*WIDTH-1 -: WIDTH];
                end
            end
            default: begin
                merged_result[SIZE*WIDTH - 1 -: 256*WIDTH]     = bfa_out;
                merged_result[WIDTH - 1 : 0]                   = adder_result[WIDTH-1 : 0];
            end
        endcase
    end
endmodule
