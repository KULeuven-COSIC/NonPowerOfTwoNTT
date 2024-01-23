`timescale 1ns / 1ps

module adders #(
    parameter WIDTH = 32,
    parameter N_ADDERS = 51
) (
    input wire [N_ADDERS*WIDTH-1:0] in_first_points,
    input wire [N_ADDERS*WIDTH-1:0] in_second_points,
    input wire [WIDTH-1:0] modulus,
    output wire [N_ADDERS*WIDTH-1:0] out_adder_result
    );
    
    wire [N_ADDERS*WIDTH-1:0] adder_result;
    
    assign out_adder_result = adder_result;
    
    genvar i;
    generate
    for (i = 0; i < N_ADDERS; i = i + 1) begin : adders
        mod_add #(.WIDTH(WIDTH)) inst_mod_add (
            .A       (in_first_points[(i+1)*WIDTH - 1 -: WIDTH] ),
            .B       (in_second_points[(i+1)*WIDTH - 1 -: WIDTH]),
            .modulus (modulus                                   ),
            .C       (adder_result[(i+1)*WIDTH - 1 -: WIDTH]    )
        );
    end
    endgenerate
endmodule
