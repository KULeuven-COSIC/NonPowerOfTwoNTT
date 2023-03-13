from util import util
import numpy as np
from functools import reduce

np.set_printoptions(linewidth=np.inf)


class Memory:
    def __init__(self, n_blocks, block_size):
        self.mem = np.zeros((n_blocks, block_size), dtype=np.int64)

    def write(self, data, address):
        block = np.arange(len(address))
        self.mem[block, address] = data

    def read(self, address):
        block = np.arange(len(address))
        return self.mem[block, address]

    def __str__(self):
        return str(self.mem)


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


def butterfly(a, b, wn, m):
    b = b * wn
    ar = (a + b) % m
    br = (a - b) % m
    return ar, br


def butterfly_array(x, wn, m):
    n = len(x)
    even = np.arange(0, n, 2)
    odd = np.arange(1, n, 2)
    a = x[even]
    b = x[odd]
    ar, br = butterfly(a, b, wn, m)
    x_out = np.zeros_like(x, dtype=np.int64)
    x_out[even] = ar
    x_out[odd] = br
    return x_out


def roll(data, shift):
    return np.roll(data, shift)


def rader(N, p_root, p_root_r, m):
    g = util.principal_root_of_unity(N - 1, N)
    g_inv = util.fast_exp(g, N - 2, N)

    N_inv = util.fast_exp(N - 1, m - 2, m)
    rader_permutation_start = [0] * (N - 1)
    rader_permutation_end = [0] * N
    b = [0] * (N - 1)

    r = np.arange(N)

    for q in range(N - 1):
        rader_permutation_start[q] = r[util.fast_exp(g, q, N)]
        rader_permutation_end[q + 1] = r[util.fast_exp(g_inv, q, N)]
        # already absorb division by N for computing inverse NTT of (A x B) in b
        b[q] = (util.fast_exp(p_root, util.fast_exp(g_inv, q, N), m) * N_inv) % m

    B = util.ntt(b, p_root_r, m)

    return Permutation(rader_permutation_start), -Permutation(rader_permutation_end), np.array(B, dtype=np.int64)


def PFA(n):
    N = reduce(lambda a, b: a * b, n)
    e = util.orthogonal_idempotents(n, N)

    A = [[0] * n[1] for _ in range(n[0])]
    for i1 in range(n[0]):
        for i2 in range(n[1]):
            A[i1][i2] = (e[0] * i1 + e[1] * i2) % N

    pfa_perm_1 = Permutation(np.array(A).flatten('F'))
    pfa_perm_2 = Permutation(np.array(A).flatten('C'))

    N1p = (e[0] * util.fast_exp(n[1], n[0] - 2, n[0])) % n[0]
    N2p = (e[1] * util.fast_exp(n[0], n[1] - 2, n[1])) % n[1]

    B = [0 for _ in range(n[0] * n[1])]
    for i in range(N):
        B[i] = (i * N1p % n[0]) * n[1] + i * N2p % n[1]

    pfa_perm_end = Permutation(np.array(B).flatten('C'))

    return pfa_perm_1, pfa_perm_2, pfa_perm_end


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



n = [257, 85]
N = reduce(lambda a, b: a * b, n)
x = list(range(N))
#m = 5441
m = 117438721

p_root_g = util.principal_root_of_unity(N, m)
e = util.orthogonal_idempotents(n, N)
stride = n[0] % n[1]

# Initialize memory
mem = Memory(n[0], n[0])
for i in range(n[1]):
    data_in = x[n[0]*i:n[0]*(i+1)]
    address = (np.arange(n[0]) * 1 + i * stride) % n[1]
    mem.write(data_in, address)

print(mem)

# First NTT of rows
p_root = util.fast_exp(p_root_g, N // n[0], m)
p_root_r = util.principal_root_of_unity(n[0]-1, m)
p_root_r_inv = util.fast_exp(p_root_r, m-2, m)
rader_perm_start, rader_perm_end, B = rader(n[0], p_root, p_root_r, m)
dit_permutations, bit_reversal, twiddle_factors = dit_fft(n[0])

reps = 1
collect_first = Permutation([i * n[0] for i in range(reps)])
collect_second = Permutation([i * (n[0] - 1) for i in range(reps)])
rader_perm_start = rader_perm_start.tile(reps, padding=1)
rader_perm_end.permutation -= 1
rader_perm_end = rader_perm_end.tile(reps, padding=0)

for i in range(n[1]):
    # Read row from memory
    address = np.full((n[0],), i) % n[1]
    data_out = mem.read(address)

    # Rader permutation
    data_permuted = rader_perm_start(data_out)
    first_points = collect_first(data_out)

    # Convolution with b
    data_permuted = bit_reversal(data_permuted)

    stages = int(np.log2(n[0]))
    # NTT
    wn = np.array([util.fast_exp(p_root_r, i, m) for i in range(n[0] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    temp = first_points
    # corresponds to summing all points in sequence
    first_points = (first_points + collect_second(data_permuted)) % m
    # multiply with b as part of convolution
    data_permuted = np.multiply(data_permuted, bit_reversal(np.tile(B, reps))) % m
    # corresponds with adding first point to each other point in final result
    data_permuted[collect_second.permutation] = (collect_second(data_permuted) + temp) % m

    # inverse NTT
    wn = np.array([util.fast_exp(p_root_r_inv, i, m) for i in range(n[0] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    data_out = np.insert(data_permuted, collect_second.permutation, first_points)

    # Write back to memory
    data_mem = roll(data_out, i)
    mem.write(data_mem, address)



# NTT of columns
pfa_perm_1, pfa_perm_2, pfa_perm_end = PFA([17, 5])

# PFA 1
address = np.arange(n[0])

n = [n[0], 17]
shift = 0
p_root = util.fast_exp(p_root_g, N // n[1], m)
p_root_r = util.principal_root_of_unity(n[1]-1, m)
p_root_r_inv = util.fast_exp(p_root_r, m-2, m)
rader_perm_start, rader_perm_end, B = rader(n[1], p_root, p_root_r, m)
dit_permutations, bit_reversal, twiddle_factors = dit_fft(n[1])

reps = 5
collect_first = Permutation([i * n[1] for i in range(reps)])
collect_second = Permutation([i * (n[1] - 1) for i in range(reps)])
rader_perm_start = rader_perm_start.tile(reps, padding=1)
rader_perm_end = rader_perm_end.tile(reps, padding=0)
bit_reversal = bit_reversal.tile(reps)
dit_permutations = [p.tile(reps) for p in dit_permutations]
twiddle_factors = [np.tile(f, reps) for f in twiddle_factors]

for i in range(n[0]):
    # Read column from memory
    data_out = mem.read(address % (n[1] * reps))
    data_shifted = roll(data_out, shift)

    # PFA permutation
    data_shifted = pfa_perm_1(data_shifted)

    # Rader permutation
    data_permuted = rader_perm_start(data_shifted)
    first_points = collect_first(data_shifted)

    # Convolution with b
    data_permuted = bit_reversal(data_permuted)
    stages = int(np.log2(n[1]))

    # NTT
    wn = np.array([util.fast_exp(p_root_r, i, m) for i in range(n[1] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    temp = first_points
    # corresponds to summing all points in sequence
    first_points = (first_points + collect_second(data_permuted)) % m
    # multiply with b as part of convolution
    data_permuted = np.multiply(data_permuted, bit_reversal(np.tile(B, reps))) % m
    # corresponds with adding first point to each other point in final result
    data_permuted[collect_second.permutation] = (collect_second(data_permuted) + temp) % m

    # inverse NTT
    wn = np.array([util.fast_exp(p_root_r_inv, i, m) for i in range(n[1] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    #data_permuted = bit_reversal(data_permuted) # This isn't strictly necessary
    data_out = np.insert(data_permuted, collect_second.permutation, first_points)

    #data_out = rader_perm_end(data_out) # This isn't strictly necessary
    #print(data_out) # This isn't strictly necessary

    # Write back to memory
    mem_old = mem.read(address % (n[1] * reps))
    mem_old = roll(mem_old, shift)
    data_out = np.concatenate((data_out[:n[1] * reps], mem_old[n[1] * reps:]))

    data_mem = roll(data_out, n[0] - shift)
    mem.write(data_mem, address % (n[1] * reps))

    shift = (shift + n[1] * reps) % n[0]
    address = roll(address, n[0] - n[1] * reps)


# PFA 2
address = np.arange(n[0])

n = [n[0], 5]
shift = 0
p_root = util.fast_exp(p_root_g, N // n[1], m)
p_root_r = util.principal_root_of_unity(n[1]-1, m)
p_root_r_inv = util.fast_exp(p_root_r, m-2, m)
rader_perm_start, rader_perm_end, B = rader(n[1], p_root, p_root_r, m)
dit_permutations, bit_reversal, twiddle_factors = dit_fft(n[1])

reps = 17
collect_first = Permutation([i * n[1] for i in range(reps)])
collect_second = Permutation([i * (n[1] - 1) for i in range(reps)])
rader_perm_start = rader_perm_start.tile(reps, padding=1)
rader_perm_end = rader_perm_end.tile(reps, padding=0)
bit_reversal = bit_reversal.tile(reps)
dit_permutations = [p.tile(reps) for p in dit_permutations]
twiddle_factors = [np.tile(f, reps) for f in twiddle_factors]

for i in range(n[0]):
    # Read column from memory
    data_out = mem.read(address % (n[1] * reps))
    data_shifted = roll(data_out, shift)

    # PFA permutation
    data_shifted = pfa_perm_2((-pfa_perm_1)(data_shifted))

    # Rader permutation
    data_permuted = rader_perm_start(data_shifted)
    first_points = collect_first(data_shifted)

    # Convolution with b
    data_permuted = bit_reversal(data_permuted)
    stages = int(np.log2(n[1]))
    # NTT
    wn = np.array([util.fast_exp(p_root_r, i, m) for i in range(n[1] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    temp = first_points
    # corresponds to summing all points in sequence
    first_points = (first_points + collect_second(data_permuted)) % m
    # multiply with b as part of convolution
    data_permuted = np.multiply(data_permuted, bit_reversal(np.tile(B, reps))) % m
    # corresponds with adding first point to each other point in final result
    data_permuted[collect_second.permutation] = (collect_second(data_permuted) + temp) % m

    # inverse NTT
    wn = np.array([util.fast_exp(p_root_r_inv, i, m) for i in range(n[1] - 1)])
    for stage in range(stages):
        data_permuted = dit_permutations[stage](data_permuted)
        w = wn[twiddle_factors[stage]]
        data_permuted = butterfly_array(data_permuted, w, m)

    #data_permuted = bit_reversal(data_permuted) # This isn't strictly necessary
    data_out = np.insert(data_permuted, collect_second.permutation, first_points)

    #data_out = rader_perm_end(data_out) # This isn't strictly necessary
    #data_out = pfa_perm_end(data_out) # This isn't strictly necessary

    # Write back to memory
    mem_old = mem.read(address % (n[1] * reps))
    mem_old = roll(mem_old, shift)
    data_out = np.concatenate((data_out[:n[1] * reps], mem_old[n[1] * reps:]))

    data_mem = roll(data_out, n[0] - shift)
    mem.write(data_mem, address % (n[1] * reps))

    shift = (shift + n[1] * reps) % n[0]
    address = roll(address, n[0] - n[1] * reps)

print(mem)

# Values are permuted in memory, so we just check if all the correct values are present in the memory
for val in util.ntt(x, p_root_g, m):
    assert val in mem.mem

