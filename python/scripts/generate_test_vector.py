import numpy as np
from reverse_reindexing import full_reverse_reindexing
from common import root_of_unity, ntt

N = 21845
m = 419424001
#p_root = root_of_unity(N, m)
p_root = 64863

np.random.seed(0)
x = np.arange(N, dtype=np.uint64) #np.random.randint(0, high=2 ** 32, size=N, dtype=np.uint64)

ntt_result = ntt(x, p_root, m)

ntt_result_shuffled = np.zeros_like(x)
ntt_result_shuffled[full_reverse_reindexing([257, 17, 5])] = ntt_result

memory_data = x.reshape([257, 85])
expected_result = ntt_result_shuffled.reshape([257, 85])

with open('memory_data.mem', 'w') as f:
    for i in range(memory_data.shape[1]):
        f.write(" ".join(f"{word:08X}" for word in memory_data[:, i]) + "\n")

with open('expected_result.mem', 'w') as f:
    for i in range(expected_result.shape[1]):
        f.write(" ".join(f"{word:08X}" for word in expected_result[:, i]) + "\n")
