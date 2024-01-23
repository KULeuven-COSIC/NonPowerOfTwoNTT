/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*
This file was modifications to include additional pipeline stages.

These modifications are licensed under the Apache License, Version 2.0, in accordance with the original work.
*/

`include "defines.v"

module ModRed_sub #(parameter CURR_DATA = 0, NEXT_DATA = 0)
                  (input                                     clk,
				   input     [(`DATA_SIZE_ARB-`W_SIZE)-1:0]  qH,
				   input     [CURR_DATA-1:0]                 T1,
				   output reg[NEXT_DATA-1:0]                 C);

// connections
reg [(`W_SIZE)-1:0]             T2L;
reg [(`W_SIZE)-1:0]             T2;

reg [(CURR_DATA - `W_SIZE)-1:0] T2H;
reg                             CARRY;

(* use_dsp = "yes" *) reg [`DATA_SIZE_ARB - 1:0]      MULT;

// --------------------------------------------------------------- multiplication of qH and T2 (and registers)
always @(*) begin
	T2L = T1[(`W_SIZE)-1:0];
    T2  = (-T2L);
end

reg [(`DATA_SIZE_ARB-`W_SIZE)-1:0]  qH_D;
reg [CURR_DATA-1:0]                 T1_D;
reg [(`W_SIZE)-1:0]                 T2L_D;
reg [(`W_SIZE)-1:0]                 T2_D;
always @(posedge clk) begin
    T1_D <= T1;
    T2L_D <= T2L;
    T2_D <= T2;
    qH_D <= qH;
end

always @(posedge clk) begin
    T2H   <= (T1_D >> (`W_SIZE));
    CARRY <= (T2L_D[`W_SIZE-1] | T2_D[`W_SIZE-1]);
    MULT  <= qH_D * T2_D;
end

// --------------------------------------------------------------- final addition operation
always @(posedge clk) begin
    C <= (MULT+T2H)+CARRY;
end

endmodule
