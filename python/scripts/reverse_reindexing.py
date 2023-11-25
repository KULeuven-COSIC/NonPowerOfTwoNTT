from util import util
import numpy as np


# Function to reverse Rader reindexing for a given size N
def reverse_rader_reindexing(N):
    g = util.principal_root_of_unity(N - 1, N)
    g_inv = util.fast_exp(g, N - 2, N)
    permutation = np.zeros(N, dtype=int)
    for q in range(N - 1):
        permutation[util.fast_exp(g_inv, q, N)] = q + 1
    return permutation


# Function to compute the bit reversal reindexing for a given size N
def reverse_bit_reversal(N):
    stages = int(np.log2(N))
    bit_r = np.zeros(1, dtype=int)
    for stage in range(1, stages + 1):
        bit_r = np.concatenate((2 * bit_r, 2 * bit_r + 1))
    bit_r_padded = np.pad(bit_r + 1, (1, 0))
    return bit_r_padded


# Function to reverse Prime Factor Algorithm (PFA) reindexing for a 2D array with size [n[0], n[1]]
def reverse_pfa_reindexing(n):
    N = n[0] * n[1]
    permutation = np.zeros(N, dtype=int)
    for i1 in range(n[0]):
        for i2 in range(n[1]):
            permutation[(n[1] * i1 + n[0] * i2) % N] = i1 * n[1] + i2
    return permutation


# Main function to apply all reverse reindexing operations for an N-dimensional array
def full_reverse_reindexing(n):
    N = np.prod(n)
    perm = np.arange(N).reshape(n)

    # Reverse staggering of memory rows
    perm_reshaped = perm.reshape(n[0], -1)
    for i in range(perm_reshaped.shape[1]):
        perm_reshaped[:, i] = np.roll(perm_reshaped[:, i], n[0] - i)
    perm = perm_reshaped.reshape(n)

    # Reverse bit-reversal and rader permutations for each dimension
    for i in range(len(n)):
        perm = np.take(perm, reverse_bit_reversal(n[i]), axis=i)
        perm = np.take(perm, reverse_rader_reindexing(n[i]), axis=i)

    # Reverse PFA permutations for each dimension
    for i in range(len(n) - 1, 0, -1):
        perm = perm.reshape(n[:i - 1] + [-1])
        indices = reverse_pfa_reindexing([n[i - 1], np.prod(n[i:])])
        perm = np.take(perm, indices, axis=-1)

    return perm


if __name__ == "__main__":
    # Example usage of the full reverse reindexing function
    shuffled_ntt_result = np.arange(257*17*5)
    reverse_reindexing_indices = full_reverse_reindexing([257, 17, 5])
    ntt_result = shuffled_ntt_result[reverse_reindexing_indices]
    print(ntt_result)
