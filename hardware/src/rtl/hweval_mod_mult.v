`timescale 1ns / 1ps

`include "defines.v"

module hweval_mod_mult (
    input   clk     ,
    input   reset  ,
    output  data_ok );

    // Define internal regs and wires
    reg  [`DATA_SIZE_ARB-1:0] A_in;
    reg  [`DATA_SIZE_ARB-1:0] B_in;
    reg  [`DATA_SIZE_ARB-1:0] q_in;
    wire [`DATA_SIZE_ARB-1:0] result;
    
    // Instantiate the multiplier    
    ModMult dut (
        .clk    (clk   ),
        .reset  (reset ),
        .A      (A_in  ),
        .B      (B_in  ),
        .q      (q_in  ),
        .C      (result));

    reg [1:0] state;

    always @(posedge(clk)) begin
    
        if (reset) begin
            A_in     <= 'd5953;
            B_in     <= 'd1229;
            q_in     <= 'd4244570881;
                        
            state    <= 2'b00;
        end else begin
    
            if (state == 2'b00) begin
                A_in     <= A_in;
                B_in     <= B_in;
                q_in     <= q_in;            
                
                state    <= 2'b01;        
            
            end else if(state == 2'b01) begin
                A_in     <= A_in;
                B_in     <= B_in;
                q_in     <= q_in;

                state    <= result[`DATA_SIZE_ARB - 1] ? 2'b10 : 2'b01;
            end
            
            else begin
                A_in     <= B_in ^ result;
                B_in     <= result;
                q_in <= result & result;
                            
                state    <= 2'b00;
            end
        end
    end
    
    assign data_ok = A_in[`DATA_SIZE_ARB - 1] & result[`DATA_SIZE_ARB - 1];    
    
endmodule