`timescale 1ns / 1ps

`include "defines.v"

`define RESET_TIME 25
`define CLK_PERIOD 10
`define DELAY (`CLK_PERIOD * (`MODRED_DELAY + `INTMUL_DELAY + 1))
`define CLK_HALF 5

module tb_dit_butterfly();
    
    parameter WIDTH = 32;
    
    // Define internal regs and wires
    reg  clk;
    reg  reset;
    reg  mode;
    reg  [WIDTH-1:0] A_in;
    reg  [WIDTH-1:0] B_in;
    reg  [WIDTH-1:0] W_in;
    reg  [WIDTH-1:0] q_in;
    wire [WIDTH-1:0] A_out;
    wire [WIDTH-1:0] B_out;
    
    reg  [WIDTH-1:0] expected_A;
    reg  [WIDTH-1:0] expected_B;
    reg  result_ok;

    // Instantiating adder
    dit_butterfly #(
        .WIDTH(WIDTH)
    ) dut (
        .clk     (clk   ),
        .reset   (reset ),
        .mode    (mode  ),
        .A       (A_in  ),
        .B       (B_in  ),
        .W       (W_in  ),
        .modulus (q_in  ),
        .A_out   (A_out ),
        .B_out   (B_out )
    );

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // Initialize signals to zero
    initial begin
        mode  <= 0;
        A_in  <= 0;
        B_in  <= 0;
        W_in  <= 0;
        q_in  <= 0;
    end

    // Reset the circuit
    initial begin
        reset = 1;
        #`RESET_TIME
        reset = 0;
    end

    task perform_butterfly;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        input [WIDTH-1:0] w;
        input [WIDTH-1:0] q;
        begin
            mode <= 1'b0;
            A_in <= a;
            B_in <= b;
            W_in <= w;
            q_in <= q;
            #`CLK_PERIOD;
        end
    endtask
    
    task perform_multiply;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        input [WIDTH-1:0] q;
        begin
            mode <= 1'b1;
            A_in <= 'hBAD;
            B_in <= a;
            W_in <= b;
            q_in <= q;
            #`CLK_PERIOD;
        end
    endtask
    
    task check_butterfly_result;
        input [WIDTH-1:0] exp_A;
        input [WIDTH-1:0] exp_B;
        begin
            expected_A <= exp_A;
            expected_B <= exp_B;
            #`CLK_PERIOD;
            result_ok = (expected_A == A_out) & (expected_B == B_out);
        end
    endtask
    
    task check_multiply_result;
        input [WIDTH-1:0] exp_A;
        begin
            expected_A <= exp_A;
            expected_B <= 'hBAD;
            #`CLK_PERIOD;
            result_ok = (expected_A == A_out);
        end
    endtask

    initial begin

    #`RESET_TIME
    
    #`CLK_PERIOD;
    
    perform_multiply('d1654615998, 'd492706063, 'd4244570881);
    perform_butterfly('d3626764237, 'd1654615998, 'd492706063, 'd4244570881);
    perform_multiply('d1806341205, 'd252997728, 'd4244570881);
    perform_butterfly('d3823568514, 'd1806341205, 'd252997728, 'd4244570881);
    perform_multiply('d4146640122, 'd1238622089, 'd4244570881);
    perform_butterfly('d1112038970, 'd4146640122, 'd1238622089, 'd4244570881);
    perform_multiply('d1739178872, 'd3387405449, 'd4244570881);
    perform_butterfly('d2087043557, 'd1739178872, 'd3387405449, 'd4244570881);
    perform_multiply('d3564191072, 'd807193490, 'd4244570881);
    perform_butterfly('d3366389305, 'd3564191072, 'd807193490, 'd4244570881);
    
    end
    
    initial begin
    
    #`RESET_TIME;
    #`DELAY;
    
    #`CLK_PERIOD;

    check_multiply_result('d703110461);
    check_butterfly_result('d85303817, 'd2923653776);
    check_multiply_result('d391301628);
    check_butterfly_result('d4214870142, 'd3432266886);
    check_multiply_result('d4205099159);
    check_butterfly_result('d1072567248, 'd1151510692);
    check_multiply_result('d1457665637);
    check_butterfly_result('d3544709194, 'd629377920);
    check_multiply_result('d4087614975);
    check_butterfly_result('d3209433399, 'd3523345211);  
    
    $display(`MODRED_DELAY + `INTMUL_DELAY);
    #`CLK_PERIOD;
    $finish;
    
    end

endmodule
