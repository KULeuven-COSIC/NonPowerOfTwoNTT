import numpy as np
import os
from common import root_of_unity, ntt
from moduli import generate_moduli

def rader(N, p_root, p_root_r, m):
    g = root_of_unity(N - 1, N)

    g_inv = pow(g, N - 2, N)

    N_inv = pow(N - 1, m - 2, m)
    b = np.zeros(N - 1, dtype=np.uint64)

    for q in range(N - 1):
        # already absorb division by N for computing inverse NTT of (A x B) in b
        b[q] = (pow(p_root, pow(g_inv, q, N), m) * N_inv) % m

    B = np.array(ntt(b, p_root_r, m), dtype=np.uint64)

    return B


def dit_fft(n):
    stages = int(np.log2(n))
    twiddle_factors = []
    tw = np.array([0])
    bit_reversal = np.array([0])

    for stage in range(1, stages + 1):
        bit_reversal = np.concatenate((2 * bit_reversal, 2 * bit_reversal + 1))
        twiddle_factors.append(np.tile(tw, 2 ** (stages - stage)))
        tw = np.concatenate((tw, tw + 2 ** (stages - stage - 1)))

    return bit_reversal, twiddle_factors


n = [257, 17, 5]
N = int(np.prod(n))
reps = [1, 15, 51]

data = [[0]*128 for _ in range(1360)]

idx = 0

# 40 largest moduli, more can be used if necessary
moduli = generate_moduli([21845, 256], count=40)

# Twiddle factors are premultiplied with R, because result of the Montgomery modular multipliers is AxBxR^(-1) mod M
w = 8
L = 4
R = 2**(L*w)

for m in moduli:
    m = int(m)

    p_root_g = root_of_unity(N, m)

    for dim in range(3):

        bit_reversal, twiddle_factors = dit_fft(n[dim])

        p_root = pow(p_root_g, N // n[dim], m)
        p_root_r = root_of_unity(n[dim]-1, m)
        p_root_r_inv = pow(p_root_r, m-2, m)

        twiddle_factors = [np.tile(f, reps[dim]) for f in twiddle_factors]

        wn = np.array([pow(p_root_r, i, m) for i in range(n[dim] - 1)], dtype=np.uint64)
        wn_inv = np.array([pow(p_root_r_inv, i, m) for i in range(n[dim] - 1)], dtype=np.uint64)

        stages = int(np.log2(n[dim]))
        for stage in range(stages):
            data[idx][:len(twiddle_factors[stage])] = (wn[twiddle_factors[stage]] * R) % m
            idx += 1

        B = rader(n[dim], p_root, p_root_r, m)

        B_data = np.tile(B[bit_reversal], 256 // len(B))

        B_data_0 = B_data[1::2]
        B_data_1 = B_data[::2]

        data[idx][:len(B_data_0)] = (B_data_0 * R) % m
        idx += 1
        data[idx][:len(B_data_1)] = (B_data_1 * R) % m
        idx += 1

        for stage in range(stages):
            data[idx][:len(twiddle_factors[stage])] = (wn_inv[twiddle_factors[stage]] * R) % m
            idx += 1

output_directory = "generated"
moduli_file_path = os.path.join(output_directory, 'moduli.mem')
twiddle_factors_file_path = os.path.join(output_directory, 'twiddle_factor_ROM.coe')

if not os.path.exists(output_directory):
    os.makedirs(output_directory)

with open(moduli_file_path, 'w') as f:
    f.write(" ".join(f"{word:08X}" for word in moduli) + "\n")
print(f"Moduli written to {moduli_file_path}")

with open(twiddle_factors_file_path, 'w') as coe_file:
    coe_file.write("memory_initialization_radix=16;\n")
    coe_file.write("memory_initialization_vector=\n")

    for line in data[:-1]:
        line = "".join(f"{p:08X}" for p in line)
        coe_file.write(f"{line},\n")
    line = "".join(f"{p:08X}" for p in data[-1])
    coe_file.write(f"{line};\n")
print(f"Twiddle factors written to {twiddle_factors_file_path}")


# Write the data to a mem file
with open("twiddle_factor_ROM.mem", "w") as f:
    for i in range(len(data[0])):
        f.write(" ".join(f"{data[j][i]:08X}" for j in range(len(data))) + "\n")
