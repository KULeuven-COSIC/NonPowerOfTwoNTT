`timescale 1ns / 1ps


module controller # (
    parameter PIPELINE_DELAY = 1
) (
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  start,
    input  wire [5:0]            mod_idx,
    output wire [8:0]            cs1_shift,
    output wire [8:0]            cs2_shift,
    output wire [257*8-1:0]      addr_read,
    output wire [257*8-1:0]      addr_write,
    output wire [256:0]          we,
    output wire [2:0]            rpp_op,
    output wire [2:0]            brp_op,
    output wire                  bfa_mode,
    output wire                  bfa_swap,
    output wire [10:0]           bfa_w_idx,
    output wire [2:0]            merge_sel,
    output wire [2:0]            add_b_in_sel,
    output wire                  done
    );
    
    // Constants
    localparam N_0 = 85;
    localparam N_1 = 256;
    localparam N_2 = 256;
    localparam NTT_STEPS_0 = 8;
    localparam NTT_STEPS_1 = 4;
    localparam NTT_STEPS_2 = 2;
    
    // Define states
    localparam IDLE = 0;
    localparam PFA_RADER_PERM = 1;
    localparam NTT_STEP = 2;
    localparam MULTIPLY_B = 3;
    localparam MULTIPLY_A = 4;
    localparam INV_NTT_STEP = 5;
    localparam WAIT_FOR_WRITE = 6;
    
    reg [2:0] state;
    reg [2:0] next_state;
    reg [1:0] stage;
    reg [8:0] row;
    reg [2:0] step;
    reg [4:0] delay;
    
    reg incr_stage;
    reg incr_row;
    reg incr_step;
    reg incr_delay;
    reg rst_stage;
    reg rst_row;
    reg rst_step;
    reg rst_delay;
    
    always @(posedge clk) begin
        if (reset || rst_stage) begin
            stage <= 'd0;
        end else if (incr_stage) begin
            stage <= stage + 1;
        end else begin
            stage <= stage;
        end
    end
    
    always @(posedge clk) begin
        if (reset || rst_row) begin
            row <= 'd0;
        end else if (incr_row) begin
            if (stage == 0) begin
                row <= row + 1;
            end else begin
                row <= row + 3;
            end
        end else begin
            row <= row;
        end
    end
    
    always @(posedge clk) begin
        if (reset || rst_step) begin
            step <= 'd0;
        end else if (incr_step) begin
            step <= step + 1;
        end else begin
            step <= step;
        end
    end
    
    always @(posedge clk) begin
        if (reset || rst_delay) begin
            delay <= 'd0;
        end else if (incr_delay) begin
            delay <= delay + 1;
        end else begin
            delay <= delay;
        end
    end
    
    wire final_row;
    wire final_step;
    wire final_delay;

    assign final_row   = ((stage == 0 && row == N_0-1) || (stage == 1 && row == N_1-1) || (stage == 2 && row == N_2-1));
    assign final_step  = ((stage == 0 && step == NTT_STEPS_0-1) || (stage == 1 && step == NTT_STEPS_1-1) || (stage == 2 && step == NTT_STEPS_2-1));
    assign final_delay = (delay == PIPELINE_DELAY-1);  

    reg [10:0] reg_w_idx;
    reg incr_w_idx;
    reg decr_w_idx;
    
    always @(posedge clk) begin
        if (reset || rst_stage) begin
            reg_w_idx <= ({4'b0, mod_idx} << 5) + ({4'b0, mod_idx} << 1); // mod_idx * 34
        end else if (incr_w_idx) begin
            reg_w_idx <= reg_w_idx + 1;
        end else if (decr_w_idx) begin
            reg_w_idx <= reg_w_idx - 1;
        end else begin
            reg_w_idx <= reg_w_idx;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
   end   
   
   // describe control flow
   always @(*) begin
        // default values
        incr_stage = 0;
        incr_row   = 0;
        incr_step  = 0;
        incr_delay = 0;
        rst_stage  = 0;
        rst_row    = 0;
        rst_step   = 0;
        rst_delay  = 0;
        incr_w_idx = 0;
        decr_w_idx = 0;
        next_state = state;
        
        case(state)
            IDLE: 
                begin
                    if (start) begin
                        next_state = PFA_RADER_PERM;
                    end
                    rst_row = 1;
                    rst_step = 1;
                    rst_stage = 1;
                end
            PFA_RADER_PERM:
                if (final_row) begin
                    next_state = NTT_STEP;
                    rst_row  = 1;
                    incr_step = 1;
                    incr_w_idx = 1;
                end else begin
                    incr_row = 1;
                end
            NTT_STEP:
                if (final_row) begin
                    if (final_step) begin
                        incr_w_idx = 1;
                        next_state = MULTIPLY_B;
                    end else begin
                        incr_step = 1;
                        incr_w_idx = 1;
                    end
                    rst_row = 1;
                end else begin
                    incr_row = 1;
                end
            MULTIPLY_B:
                begin
                    next_state = MULTIPLY_A;
                    incr_w_idx = 1;
                end
            MULTIPLY_A:
                if (final_row) begin
                    next_state = INV_NTT_STEP;
                    rst_row  = 1;
                    rst_step = 1;
                    incr_w_idx = 1;
                end else begin
                    next_state = MULTIPLY_B;
                    incr_row = 1;
                    decr_w_idx = 1;
                end
            INV_NTT_STEP:
                if (final_row) begin
                    if (final_step) begin
                        next_state = WAIT_FOR_WRITE;
                        rst_delay = 1;
                    end else begin
                        incr_step = 1;
                        incr_w_idx = 1;
                    end
                    rst_row = 1;
                end else begin
                    incr_row = 1;
                end
            WAIT_FOR_WRITE:
                begin
                    if (final_delay) begin
                        if (stage == 3) begin
                            next_state = IDLE;
                        end else begin
                            next_state = PFA_RADER_PERM;
                        end
                    end else if (delay == 0) begin
                        incr_stage = 1;
                        incr_w_idx = 1;
                    end
                    rst_row  = 1;
                    rst_step = 1;
                    incr_delay = 1;
                end
            default:
                next_state = IDLE;
        endcase
    end
          
    // describe control signals
    
    wire [256:0]     mem_we;
    wire [257*8-1:0] addr;
    
    mem_control mem_control_inst (
        .clk        (clk                ),
        .reset      (reset              ),
        .soft_reset (rst_row            ),
        .stage      (stage              ),
        .incr       (incr_row           ),
        .addr       (addr               ),
        .we         (mem_we             ),
        .cs1_shift  (cs1_shift          ),
        .cs2_shift  (cs2_shift          )
    );
    
    reg                  ctrl_rpp_mode;
    reg [2:0]            ctrl_brp_op;
    reg                  ctrl_bfa_mode;
    reg                  ctrl_bfa_swap;
    reg                  ctrl_merge_mode;
    reg [2:0]            ctrl_add_b_in_sel;
    reg                  ctrl_we;
    
    assign rpp_op       = {ctrl_rpp_mode, stage};
    assign brp_op       = ctrl_brp_op;
    assign bfa_mode     = ctrl_bfa_mode;
    assign bfa_swap     = ctrl_bfa_swap;
    assign add_b_in_sel = ctrl_add_b_in_sel;
    assign merge_sel    = {ctrl_merge_mode, stage};
    assign addr_read    = addr;
    assign addr_write   = addr;
    assign we           = ctrl_we ?
                                (mem_we & {2'b11, {85{(stage == 0) || (row != 0)}}, {170{1'b1}}})
                            :
                                257'b0;
    assign bfa_w_idx    = reg_w_idx;
    assign done         = state == IDLE;
    
    always @(*) begin
        case(state)
            IDLE: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= 0;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 0;
            end
            PFA_RADER_PERM: begin
                ctrl_rpp_mode       <= 1;
                ctrl_brp_op         <= step;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 1;
            end
            NTT_STEP: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= step;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 1;
            end
            MULTIPLY_B: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= 0;
                ctrl_bfa_mode       <= 1;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= {1'b1, stage};
                ctrl_we             <= 0;
            end
            MULTIPLY_A: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= 0;
                ctrl_bfa_mode       <= 1;
                ctrl_bfa_swap       <= 1;
                ctrl_merge_mode     <= 1;
                ctrl_add_b_in_sel   <= {1'b0, stage};
                ctrl_we             <= 1;
            end
            INV_NTT_STEP: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= step;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 1;
            end
            WAIT_FOR_WRITE: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= 0;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 0;
            end
            default: begin
                ctrl_rpp_mode       <= 0;
                ctrl_brp_op         <= 0;
                ctrl_bfa_mode       <= 0;
                ctrl_bfa_swap       <= 0;
                ctrl_merge_mode     <= 0;
                ctrl_add_b_in_sel   <= 3;
                ctrl_we             <= 0;
            end
        endcase
    end
    
       
   
endmodule
