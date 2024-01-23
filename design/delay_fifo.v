`timescale 1ns / 1ps


module delay_fifo #(
    parameter DELAY = 1,
    parameter WIDTH = 32
) (
    input  wire             clk,
    input  wire             reset,
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    
    reg [WIDTH-1:0] shift_reg [0:DELAY-1];
    
    always @(posedge clk) begin : shift_logic
        integer i;
        if (reset) begin // reset
            for (i = 0; i < DELAY; i=i+1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            for (i = 1; i < DELAY; i=i+1) begin // Shift the data to the right
                shift_reg[i] <= shift_reg[i-1];
            end
            shift_reg[0] <= data_in; // Input new data at the left end
        end
    end
    
    assign data_out = shift_reg[DELAY-1];
    
endmodule
