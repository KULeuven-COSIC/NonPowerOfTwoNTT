import numpy as np
import os
from common import root_of_unity


def bit_reversal(N):
    stages = int(np.log2(N))
    bit_r = np.zeros(1, dtype=int)
    for stage in range(1, stages + 1):
        bit_r = np.concatenate((2 * bit_r, 2 * bit_r + 1))
    return bit_r


def rader_permutation(N):
    g = root_of_unity(N - 1, N)
    rader_perm = np.zeros(N - 1, dtype=int)
    for q in range(N - 1):
        rader_perm[q] = pow(g, q, N)
    return rader_perm


def pfa_permutation(n):
    A = np.zeros(n, dtype=int)
    stride = n[0] % n[1]
    for i in range(n[1]):
        row_indices = (np.arange(n[0]) + i * stride) % n[1]
        A[np.arange(n[0]), row_indices] = np.arange(n[0] * i, n[0] * (i + 1))
    return A.flatten('F')


def tile_permutation(perm, reps, padding=0):
    length = perm.size + padding
    return np.concatenate([perm + (i * length) for i in range(reps)])


merged_perm = [np.array([])] * 8
merged_perm[0] = rader_permutation(257)
merged_perm[0] = merged_perm[0][bit_reversal(256)]

merged_perm[1] = tile_permutation(pfa_permutation([17, 5]), 3)
merged_perm[1] = merged_perm[1][tile_permutation(rader_permutation(17), 15, padding=1)]
merged_perm[1] = merged_perm[1][tile_permutation(bit_reversal(16), 15)]

merged_perm[2] = np.arange(5*17).reshape([17, 5], order="F").flatten()
merged_perm[2] = tile_permutation(merged_perm[2], 3)
merged_perm[2] = merged_perm[2][tile_permutation(rader_permutation(5), 51, padding=1)]
merged_perm[2] = merged_perm[2][tile_permutation(bit_reversal(4), 51)]


first_points = [np.array([])] * 8
first_points[0] = np.array([0])
first_points[1] = tile_permutation((np.arange(5) * 51) % 85, 3, padding=(85 - 5))
first_points[2] = tile_permutation(np.arange(17), 3, padding=(85 - 17))

numbers = np.arange(255)
merged_perm[4] = np.arange(1, 257)
merged_perm[5] = numbers[numbers % 17 != 0]
merged_perm[6] = numbers[numbers % 5 != 0]
first_points[4] = np.array([0])
first_points[5] = numbers[numbers % 17 == 0]
first_points[6] = numbers[numbers % 5 == 0]


p0_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[0]))
p1_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[1]))
p2_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[2]))

p4_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[4]))
p5_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[5]))
p6_lst = ", ".join(f"input_list[{p}]" for p in reversed(merged_perm[6]))

fp0_lst = ", ".join(f"input_list[{p}]" for p in first_points[0])
fp1_lst = ", ".join(f"input_list[{p}]" for p in first_points[1])
fp2_lst = ", ".join(f"input_list[{p}]" for p in first_points[2])

fp4_lst = ", ".join(f"input_list[{p}]" for p in first_points[4])
fp5_lst = ", ".join(f"input_list[{p}]" for p in first_points[5])
fp6_lst = ", ".join(f"input_list[{p}]" for p in first_points[6])

permutation_assign_string = f"""
    assign permutation[0] = {{{fp4_lst + ", " + p4_lst}}};
    assign permutation[1] = {{{fp5_lst + f", {32 * (257 - len(merged_perm[5]) - len(first_points[5]))}'b0, " + p5_lst}}};
    assign permutation[2] = {{{fp6_lst + f", {32 * (257 - len(merged_perm[6]) - len(first_points[6]))}'b0, " + p6_lst}}};
    assign permutation[3] = 'h0;
    assign permutation[4] = {{{fp0_lst + ", " + p0_lst}}};
    assign permutation[5] = {{{fp1_lst + f", {32 * (257 - len(merged_perm[1]) - len(first_points[1]))}'b0, " + p1_lst}}};
    assign permutation[6] = {{{fp2_lst + f", {32 * (257 - len(merged_perm[2]) - len(first_points[2]))}'b0, " + p2_lst}}};
"""

code = f"""`timescale 1ns / 1ps


module merged_permutation #(  
    parameter SIZE = 257,
    parameter WIDTH = 32
 ) (   
  input  wire  [SIZE-1:0][WIDTH-1:0] input_list,
  input  wire  [2:0]                 perm_select,
  output wire  [SIZE-1:0][WIDTH-1:0] output_list
);  
    wire [SIZE*WIDTH-1:0] permutation [0:6];
{permutation_assign_string}
    assign output_list = permutation[perm_select];

endmodule
"""

output_directory = "generated"
file_path = os.path.join(output_directory, 'merged_permutation.v')

if not os.path.exists(output_directory):
    os.makedirs(output_directory)

with open(file_path, 'w') as f:
    f.write(code)
print(f"Output written to {file_path}")
