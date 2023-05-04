`timescale 1ns / 1ps

`include "defines.v"

`define RESET_TIME 25
`define CLK_PERIOD 10
`define DELAY (`CLK_PERIOD * (`MODRED_DELAY + `INTMUL_DELAY))
`define CLK_HALF 5

module tb_mod_mult();
    
    // Define internal regs and wires
    reg  clk;
    reg  reset;
    reg  [`DATA_SIZE_ARB-1:0] A_in;
    reg  [`DATA_SIZE_ARB-1:0] B_in;
    reg  [`DATA_SIZE_ARB-1:0] q_in;
    wire [`DATA_SIZE_ARB-1:0] result;
    
    reg  [`DATA_SIZE_ARB-1:0] expected;
    reg  result_ok;

    // Instantiating adder
    ModMult dut (
        .clk    (clk   ),
        .reset  (reset ),
        .A      (A_in  ),
        .B      (B_in  ),
        .q      (q_in  ),
        .C      (result));

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // Initialize signals to zero
    initial begin
        A_in  <= 0;
        B_in  <= 0;
        q_in  <= 0;
    end

    // Reset the circuit
    initial begin
        reset = 1;
        #`RESET_TIME
        reset = 0;
    end

    task perform_multiply;
        input [`DATA_SIZE_ARB-1:0] a;
        input [`DATA_SIZE_ARB-1:0] b;
        input [`DATA_SIZE_ARB-1:0] q;
        begin
            A_in <= a;
            B_in <= b;
            q_in <= q;
            #`CLK_PERIOD;
        end
    endtask
    
    task check_result;
        input [`DATA_SIZE_ARB-1:0] exp;
        begin
            expected <= exp;
            #`CLK_PERIOD;
            result_ok = (expected == result);
            $display("result calculated=%x", result);
            $display("result expected  =%x", expected);
            $display("error            =%x", expected - result);
        end
    endtask

    initial begin

    #`RESET_TIME
    
    #`CLK_PERIOD;
    
    perform_multiply('d3626764237, 'd1654615998, 'd4244570881);
    perform_multiply('d3255389356, 'd3823568514, 'd4244570881);
    perform_multiply('d1806341205, 'd173879092, 'd4244570881);
    perform_multiply('d1112038970, 'd4146640122, 'd4244570881);
    perform_multiply('d2195908194, 'd2087043557, 'd4244570881);
    perform_multiply('d1739178872, 'd3943786419, 'd4244570881);
    perform_multiply('d3366389305, 'd3564191072, 'd4244570881);
    perform_multiply('d1302718217, 'd4156669319, 'd4244570881);
    perform_multiply('d2046968324, 'd1537810351, 'd4244570881);
    perform_multiply('d2505606783, 'd3829653368, 'd4244570881);
    
    end
    
    initial begin
    
    #`RESET_TIME;
    #`DELAY;
    
    #`CLK_PERIOD;
    
    check_result('d1366673678);
    check_result('d207737889);
    check_result('d2208500963);
    check_result('d609457341);
    check_result('d4050546605);
    check_result('d96306676);
    check_result('d2507092239);
    check_result('d500325575);
    check_result('d3971304583);
    check_result('d4137842576);
    
    $display(`MODRED_DELAY + `INTMUL_DELAY);
    #`CLK_PERIOD;
    $finish;
    
    end

endmodule
