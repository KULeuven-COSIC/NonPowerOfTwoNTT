perm = [[]]*8
fp = [[]]*8
perm[0] = [1, 256, 241, 16, 64, 193, 4, 253, 249, 8, 128, 129, 2, 255, 225, 32, 136, 121, 137, 120, 223, 34, 30, 227, 197, 60, 189, 68, 15, 242, 17, 240, 81, 176, 246, 11, 44, 213, 67, 190, 123, 134, 88, 169, 162, 95, 235, 22, 222, 35, 46, 211, 73, 184, 117, 140, 23, 234, 146, 111, 187, 70, 92, 165, 9, 248, 113, 144, 62, 195, 36, 221, 185, 72, 124, 133, 18, 239, 226, 31, 196, 61, 205, 52, 208, 49, 13, 244, 231, 26, 159, 98, 135, 122, 153, 104, 215, 42, 158, 99, 139, 118, 89, 168, 79, 178, 21, 236, 173, 84, 59, 198, 199, 58, 157, 100, 143, 114, 25, 232, 207, 50, 29, 228, 141, 116, 57, 200, 3, 254, 209, 48, 192, 65, 12, 245, 233, 24, 127, 130, 6, 251, 161, 96, 151, 106, 154, 103, 155, 102, 90, 167, 77, 180, 53, 204, 45, 212, 51, 206, 243, 14, 224, 33, 132, 125, 201, 56, 112, 145, 7, 250, 229, 28, 191, 66, 152, 105, 138, 119, 219, 38, 94, 163, 69, 188, 181, 76, 47, 210, 19, 238, 27, 230, 82, 175, 186, 71, 108, 149, 41, 216, 115, 142, 54, 203, 164, 93, 74, 183, 101, 156, 110, 147, 39, 218, 179, 78, 220, 37, 148, 109, 202, 55, 131, 126, 217, 40, 160, 97, 10, 247, 237, 20, 63, 194, 5, 252, 177, 80, 83, 174, 214, 43, 172, 85, 75, 182, 107, 150, 87, 170, 166, 91, 171, 86]
fp[0] = [0]
perm[1] = [35, 50, 30, 55, 60, 25, 15, 70, 20, 65, 5, 80, 10, 75, 45, 40, 1, 16, 81, 21, 26, 76, 66, 36, 71, 31, 56, 46, 61, 41, 11, 6, 52, 67, 47, 72, 77, 42, 32, 2, 37, 82, 22, 12, 27, 7, 62, 57, 18, 33, 13, 38, 43, 8, 83, 53, 3, 48, 73, 63, 78, 58, 28, 23, 69, 84, 64, 4, 9, 59, 49, 19, 54, 14, 39, 29, 44, 24, 79, 74]
fp[1] = [0, 51, 17, 68, 34]
perm[2] = [17, 68, 34, 51, 18, 69, 35, 52, 19, 70, 36, 53, 20, 71, 37, 54, 21, 72, 38, 55, 22, 73, 39, 56, 23, 74, 40, 57, 24, 75, 41, 58, 25, 76, 42, 59, 26, 77, 43, 60, 27, 78, 44, 61, 28, 79, 45, 62, 29, 80, 46, 63, 30, 81, 47, 64, 31, 82, 48, 65, 32, 83, 49, 66, 33, 84, 50, 67]
fp[2] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

perm[4] = list(range(1, 257))
fp[4] = [0]
perm[5] = [number for number in range(85) if number % 17 != 0]
fp[5] = [number for number in range(85) if number % 17 == 0]
perm[6] = [number for number in range(85) if number % 5 != 0]
fp[6] = [number for number in range(85) if number % 5 == 0]

# <-- CODEGEN -->
p0_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[0]))
p1_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[1]))
p2_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[2]))

p4_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[4]))
p5_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[5]))
p6_lst = ", ".join(f"input_list[{p}]" for p in reversed(perm[6]))

fp0_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[0]))
fp1_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[1]))
fp2_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[2]))

fp4_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[4]))
fp5_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[5]))
fp6_lst = ", ".join(f"input_list[{p}]" for p in reversed(fp[6]))

print(f"""
    assign permutation[6] = {{{fp0_lst + ", " + p0_lst}}};
    assign permutation[5] = {{{fp1_lst + f", {32 * (257 - len(perm[1]) - len(fp[1]))}'b0, " + p1_lst}}};
    assign permutation[4] = {{{fp2_lst + f", {32 * (257 - len(perm[2]) - len(fp[2]))}'b0, " + p2_lst}}};
    assign permutation[3] = 'hx;
    assign permutation[2] = {{{fp4_lst + ", " + p4_lst}}};
    assign permutation[1] = {{{fp5_lst + f", {32 * (257 - len(perm[5]) - len(fp[5]))}'b0, " + p5_lst}}};
    assign permutation[0] = {{{fp6_lst + f", {32 * (257 - len(perm[6]) - len(fp[6]))}'b0, " + p6_lst}}};
""")
# <-- END CODEGEN -->

import numpy as np
N = 257
lst = []

for perm_select in range(3):
    list_in = np.arange(N, dtype=np.uint32)

    result = [list_in[p] for p in perm[perm_select]]
    result += [0] * (257 - len(perm[perm_select]) - len(fp[perm_select]))
    result += [list_in[p] for p in fp[perm_select]]

    lst.append((list_in, perm_select, result))


for list_in, perm_select, result in lst:
    print("#`CLK_PERIOD;")
    print("input_list = {", ", ".join(f"32'd{a}" for a in reversed(list_in)), "};", sep="")
    print(f"perm_select = 2'd{perm_select};")
    print("expected = {", ", ".join(f"32'd{a}" for a in reversed(result)), "};", sep="")
    print("#`CLK_PERIOD;")
    print("result_ok = (expected == result);")
    print("$display(\"result_ok = %x\", result_ok);\n")