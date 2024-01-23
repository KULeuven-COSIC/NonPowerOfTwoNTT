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

module ModMult(input clk,
               input [`DATA_SIZE_ARB-1:0] A,B,
               input [`DATA_SIZE_ARB-1:0] q,
               output[`DATA_SIZE_ARB-1:0] C);

// --------------------------------------------------------------- connections
wire [(2*`DATA_SIZE_ARB)-1:0] P;

reg [`DATA_SIZE_ARB-1:0] A_D, B_D;
always @(posedge clk) begin
    A_D <= A;
    B_D <= B;
end

// --------------------------------------------------------------- modules
intMult im(clk,A_D,B_D,P);
ModRed  mr(clk,q,P,C);

endmodule
