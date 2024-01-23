import numpy as np
import os
from reverse_reindexing import full_reverse_reindexing
from common import root_of_unity, ntt

# NTT size
N = 21845
print(f"NTT size: {N}")
# Prime modulus from moduli.mem
m = 0x89AA2101
print(f"Prime modulus: {m}")  # Display the modulus in hexadecimal
# principal N-th root of unity in Z_m
p_root = root_of_unity(N, m)
print(f"Principal {N}-th root of unity: {p_root}")
# Generate random input data
seed = 0
np.random.seed(seed)
x = np.random.randint(0, high=2**32, size=N, dtype=np.uint64)
print(f"Random seed: {seed}")

# Initialize memory, this setup has no extra cost in hardware
memory_data = np.zeros([257, 85], dtype=np.uint32)
stride = 257 % 85
# Initial PFA permutation
for i in range(85):
    address = (np.arange(257) + i * stride) % 85
    memory_data[np.arange(257), address] = x[257 * i: 257 * (i + 1)]
# Offset rows
for i in range(85):
    memory_data[:, i] = np.roll(memory_data[:, i], i)

# Expected result
ntt_result = ntt(x, p_root, m)
ntt_result_shuffled = np.zeros_like(ntt_result)
ntt_result_shuffled[full_reverse_reindexing([257, 17, 5])] = ntt_result
expected_result = ntt_result_shuffled.reshape([257, 85])

output_directory = "generated"
init_file_path = os.path.join(output_directory, 'memory_data.mem')
result_file_path = os.path.join(output_directory, 'expected_result.mem')

if not os.path.exists(output_directory):
    os.makedirs(output_directory)

with open(init_file_path, 'w') as f:
    for row in memory_data.T:
        f.write(" ".join(f"{word:08X}" for word in row) + "\n")
print(f"Initial memory data written to {init_file_path}")

with open(result_file_path, 'w') as f:
    for row in expected_result.T:
        f.write(" ".join(f"{word:08X}" for word in row) + "\n")
print(f"Expected results written to {result_file_path}")
