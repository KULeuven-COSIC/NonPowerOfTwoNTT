import numpy as np

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

    def __str__(self):
        return str(list(self.permutation))

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

N = 256
combined_permutations, bit_r, twiddle_factors = dit_fft(N)

lst = []

for depth in range(8):
    list_in = np.arange(N, dtype=np.uint32)
    result = combined_permutations[depth](list_in)
    #perm_en = (0b11 << depth) >> 1
    step = depth
    lst.append((list_in, step, result))


for list_in, step, result in lst:
    print("#`CLK_PERIOD;")
    print("input_list = {", ", ".join(f"32'd{a}" for a in reversed(list_in)), "};", sep="")
    #print(f"perm_enable = 8'b{bin(perm_en)[2:]};")
    print(f"step = 3'd{step};")
    print("expected = {", ", ".join(f"32'd{a}" for a in reversed(result)), "};", sep="")
    print("#`CLK_PERIOD;")
    print("result_ok = (expected == result);")
    print("$display(\"result_ok = %x\", result_ok);\n")
