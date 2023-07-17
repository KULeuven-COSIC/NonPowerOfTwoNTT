from util import util
import numpy as np
from functools import reduce


class Permutation:
    def __init__(self, permutation):
        self.permutation = np.asarray(permutation, dtype=np.int64)

    def __call__(self, data):
        return data[self.permutation]

    def __mul__(self, other):
        # Combine permutations
        return Permutation(other(self.permutation))

    def __add__(self, other):
        # Concatenate permutations
        return Permutation(other[self.permutation])

    def __neg__(self):
        # Invert permutation
        s = np.zeros(self.permutation.size, self.permutation.dtype)
        s[self.permutation] = np.arange(self.permutation.size)
        return Permutation(s)

    def tile(self, reps, padding=0):
        length = self.permutation.size + padding
        return Permutation(np.concatenate([self.permutation + (i * length) for i in range(reps)]))

    def pad(self, pad_width):
        return Permutation(np.concatenate((
                np.arange(pad_width[0]),
                self.permutation + pad_width[0],
                np.arange(pad_width[1]) + (pad_width[0] + self.permutation.size)
        )))

    def append(self, other):
        return Permutation(np.concatenate((self.permutation, other.permutation)))


def rader(N, p_root, p_root_r, m):
    g = util.principal_root_of_unity(N - 1, N)
    g_inv = util.fast_exp(g, N - 2, N)

    N_inv = util.fast_exp(N - 1, m - 2, m)
    b = [0] * (N - 1)

    for q in range(N - 1):
        # already absorb division by N for computing inverse NTT of (A x B) in b
        b[q] = (util.fast_exp(p_root, util.fast_exp(g_inv, q, N), m) * N_inv) % m

    B = util.ntt(b, p_root_r, m)

    return np.array(B, dtype=np.int64)


def dit_fft(n):
    stages = int(np.log2(n))
    permutations = []
    combined_permutations = []
    twiddle_factors = []
    tw = np.array([0])
    bit_r = np.array([0])
    for stage in range(1, stages + 1):
        bit_r = np.concatenate((2 * bit_r, 2 * bit_r + 1))
        perm = Permutation(
            np.concatenate(tuple(bit_r + i * 2 ** stage for i in range(2 ** (stages - stage))))
        )
        if permutations:
            combined_permutations.append(permutations[-1] * perm)
        else:
            combined_permutations.append(perm)
        permutations.append(perm)

        twiddle_factors.append(np.tile(tw, 2 ** (stages - stage)))
        tw = np.concatenate((tw, tw + 2 ** (stages - stage - 1)))

    return combined_permutations, Permutation(bit_r), twiddle_factors



n = [257, 17, 5]
N = reduce(lambda a, b: a * b, n)
reps = [1, 5*3, 17*3]

data = [[0]*128 for _ in range(1360)]

idx = 0

from moduli import moduli

print(len(moduli[-40:]))

print("{", ", ".join([f"32'd{m}" for m in reversed(moduli[-40:])]), "}")

w = 8
L = 4
R = 2**(L*w)

for m in moduli[-40:]:
    m = int(m)
    #p_root_g = util.fast_exp(2, (m - 1) // N, m)

    p_root_g = util.principal_root_of_unity(N, m)

    for dim in range(3):
        _, bit_reversal, twiddle_factors = dit_fft(n[dim])

        p_root = util.fast_exp(p_root_g, N // n[dim], m)
        p_root_r = util.principal_root_of_unity(n[dim]-1, m)
        p_root_r_inv = util.fast_exp(p_root_r, m-2, m)

        twiddle_factors = [np.tile(f, reps[dim]) for f in twiddle_factors]

        wn = np.array([util.fast_exp(p_root_r, i, m) for i in range(n[dim] - 1)])
        wn_inv = np.array([util.fast_exp(p_root_r_inv, i, m) for i in range(n[dim] - 1)])

        stages = int(np.log2(n[dim]))

        for stage in range(stages):
            data[idx][:len(twiddle_factors[stage])] = (wn[twiddle_factors[stage]] * R) % m
            idx += 1

        B = rader(n[dim], p_root, p_root_r, m)
        print(len(B))
        bit_reversal = bit_reversal.tile(256//len(B))
        B_data = bit_reversal(np.tile(B, 256//len(B)))
        B_data_0 = B_data[1::2]
        B_data_1 = B_data[::2]
        print(len(B_data_0), len(B_data_1))
        data[idx][:len(B_data_0)] = (B_data_0 * R) % m
        idx += 1
        data[idx][:len(B_data_1)] = (B_data_1 * R) % m
        idx += 1

        for stage in range(stages):
            data[idx][:len(twiddle_factors[stage])] = (wn_inv[twiddle_factors[stage]] * R) % m
            idx += 1

print(len(data) / 40)

# Write the data to a mem file
with open("twiddle_factor_tables.mem", "w") as f:
    for i in range(len(data[0])):
        f.write(" ".join(f"{data[j][i]:08X}" for j in range(len(data))) + "\n")
