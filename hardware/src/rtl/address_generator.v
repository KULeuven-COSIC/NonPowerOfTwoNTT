`timescale 1ns / 1ps


module address_generator(
        input  wire                  clk,
        input  wire                  reset,
        input  wire                  mode,
        input  wire                  incr,
        output wire [256:0][7:0]     addr
    );
    
    localparam SIZE  = 257;
    localparam DEPTH = 85;
    localparam SHIFT = 85*3;
    
    reg  [7:0] address_reg            [0:256];
    wire [7:0] next_addr_add          [0:256];
    wire [7:0] next_addr_shift        [0:256];
    wire [7:0] next_addr_incr         [0:256];
    wire [7:0] next_addr              [0:256];
    
    genvar i;
    generate
    for (i = 0; i < SIZE; i = i + 1) begin
        mod_add #(.WIDTH(8)) add (
            .A(address_reg[i]),
            .B(8'd1),
            .modulus(DEPTH[7:0]),
            .C(next_addr_add[i])
        );
        
        assign next_addr_shift[i]  = address_reg[(i + SHIFT) % SIZE];
        assign next_addr_incr[i]   = mode ? next_addr_shift[i] : next_addr_add[i];
        
        assign next_addr[i]        = incr ? next_addr_incr[i] : address_reg[i];
        
        always @(posedge clk) begin
             address_reg[i] <= reset ? (mode ? (i % DEPTH) : 0) : next_addr[i];
        end
        
        assign addr[i] = address_reg[i];
    end
    endgenerate
    
endmodule
