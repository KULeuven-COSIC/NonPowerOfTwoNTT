`timescale 1ns / 1ps

module montgomery(
    input           clk,
    input           resetn,
    input           start,
    input  [1023:0] in_a,
    input  [1023:0] in_b,
    input  [1023:0] in_m,
    output [1023:0] result,  
    output  reg     done
     );
    
    parameter ITERATIONS_PER_CYCLE = 4; // Should be a power of 2
    
    reg [1023:0] regA;
    reg regA_en;
    reg regA_shift;
    always @(posedge clk) begin
        if (~resetn)
            regA <= 1024'b0;
        else if (regA_en)
            regA <= in_a;
        else if (regA_shift)
            regA <= {{ITERATIONS_PER_CYCLE{1'b0}}, regA[1023:ITERATIONS_PER_CYCLE]};
    end
    
    reg [1023:0] regB;
    reg regB_en;
    always @(posedge clk) begin
        if (~resetn)
            regB <= 1024'b0;
        else if (regB_en)
            regB <= in_b;
    end
    
    reg [1023:0] regM;
    reg regM_en;
    always @(posedge clk) begin
        if (~resetn)
            regM <= 1024'b0;
        else if (regM_en)
            regM <= in_m;
    end
    
    wire [1023:0] sum[0:ITERATIONS_PER_CYCLE];
    wire [1023:0] carry[0:ITERATIONS_PER_CYCLE];
    
    reg [1023:0] regSum;
    reg [1023:0] regCarry;
       
    assign sum[0] = regSum;
    assign carry[0] = regCarry;
    
    genvar i;
    generate
    for (i=1; i<=ITERATIONS_PER_CYCLE; i=i+1) begin : generate_block
        mod_add_div2 a (
            .A(sum[i-1]),
            .B(carry[i-1]),
            .C(regB & {1024{regA[i-1]}}),
            .M(regM),
            .sum(sum[i]),
            .carry(carry[i])
        );
    end 
    endgenerate
    
    reg regS_rst;
    always @(posedge clk) begin
        if (~resetn | regS_rst) begin
            regSum   <= 1024'b0;
            regCarry <= 1024'b0;
        end else begin
            regSum   <= sum[ITERATIONS_PER_CYCLE];
            regCarry <= carry[ITERATIONS_PER_CYCLE];
        end
    end
    
    reg regSubtract_en;
    
    reg muxA_sel;
    reg muxB_sel;
    wire [1024:0] add_a;
    wire [1023:0] add_b;
    wire [1027:0] add_result;
    reg  [1027:0] regResult;
    
    assign add_a = muxA_sel == 0 ? {1'b0, regSum} : add_result[1024:0];
    assign add_b = muxB_sel == 0 ? regCarry : regM;
    
    assign result = regResult;
    
    mpadder add (
        .clk(clk),
        .resetn(resetn),
        .start(1'b1),
        .subtract(regSubtract_en),
        .in_a({2'b0, add_a}),
        .in_b({3'b0, add_b}),
        .result(add_result),
        .done()
    );
    
    always @(posedge clk) begin
        regResult <= add_result;
    end    
    
    // control
    
    // idle, multiplication, final sum, modular reduction
    
    reg [10-$clog2(ITERATIONS_PER_CYCLE):0] count;
    reg regCount_rst;
    always @(posedge clk) begin
        if (~resetn | regCount_rst)
            count <= {(11-$clog2(ITERATIONS_PER_CYCLE)){1'b0}};
        else
            count <= count + 1'b1;
    end
    
    
    // Describe state machine registers
    reg [1:0] state, nextstate;

    always @(posedge clk) begin
        if(~resetn)    state <= 2'd0;
        else           state <= nextstate;
    end

    // Describe signals at each state
    always @(*)
    begin
        case(state)

            // Idle state;
            2'd0: begin
                regSubtract_en <= 1'b0;
                regA_en        <= 1'b1;
                regA_shift     <= 1'b0;
                regB_en        <= 1'b1;
                regM_en        <= 1'b1;
                muxA_sel       <= 1'b0;
                muxB_sel       <= 1'b0;
                regCount_rst   <= 1'b1;
                regS_rst       <= 1'b1;
            end

            // Do multiplication
            2'd1: begin
                regSubtract_en <= 1'b0;
                regA_en        <= 1'b0;
                regA_shift     <= 1'b1;
                regB_en        <= 1'b0;
                regM_en        <= 1'b0;
                muxA_sel       <= 1'b0;
                muxB_sel       <= 1'b0;
                regCount_rst   <= 1'b0;
                regS_rst       <= 1'b0;
            end
            
            //  Subtract modulus until done
            2'd2: begin
                regSubtract_en <= 1'b1;
                regA_en        <= 1'b0;
                regA_shift     <= 1'b1;
                regB_en        <= 1'b0;
                regM_en        <= 1'b0;
                muxA_sel       <= 1'b1;
                muxB_sel       <= 1'b1;
                regCount_rst   <= 1'b1;
                regS_rst       <= 1'b0;
            end
            
            
            default: begin
                regSubtract_en <= 1'b0;
                regA_en        <= 1'b0;
                regA_shift     <= 1'b0;
                regB_en        <= 1'b0;
                regM_en        <= 1'b0;
                muxA_sel       <= 1'b0;
                muxB_sel       <= 1'b0;
                regCount_rst   <= 1'b0;
                regS_rst       <= 1'b0;
            end

        endcase
    end
    
    // Describe next_state logic

    always @(*)
    begin
        case(state)
            2'd0: begin
                if(start)
                    nextstate <= 2'd1;
                else
                    nextstate <= 2'd0;
            end
            2'd1: begin
                if(count[10-$clog2(ITERATIONS_PER_CYCLE)])
                    nextstate <= 2'd2;
                else
                    nextstate <= 2'd1;
            end
            2'd2: begin
                if(done)
                    nextstate <= 2'd0;
                else
                    nextstate <= 2'd2; 
            end
            default: nextstate <= 2'd0;
        endcase
    end
    
    // Describe done signal
    always @(*) done <= add_result[1027] & state[1];
    
endmodule


module mod_add_div2 (
    input wire [1023:0]  A,
    input wire [1023:0]  B,
    input wire [1023:0]  C,
    input wire [1023:0]  M,
    output wire [1023:0] sum,
    output wire [1023:0] carry
    );
    
    // If A + B + C is even then sum + carry = (A + B + C) / 2
    // If A + B + C is uneven, then sum + carry = (A + B + C + M) / 2
    
    wire [1023:0] sumT;
    wire [1023:0] carryT;
    wire [1023:0] cM;
    
    assign sumT = A ^ B ^ C;
    assign carryT = (A & B) | (A & C) | (B & C);
    
    assign cM = M & {1024{sumT[0]}};
    
    assign sum = {carryT[1023], sumT[1023:1] ^ carryT[1022:0] ^ cM[1023:1]};
    assign carry = {(sumT[1023:1] & carryT[1022:0]) | (sumT[1023:1] & cM[1023:1]) | (carryT[1022:0] & cM[1023:1]), sumT[0] & cM[0]};
    
endmodule
