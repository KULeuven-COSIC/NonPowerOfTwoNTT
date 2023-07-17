from util import util
import numpy as np
from functools import reduce

np.set_printoptions(linewidth=np.inf)
#np.set_printoptions(threshold=np.inf)


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


def roll(data, shift):
    return np.roll(data, shift)



n = [257, 85]

N = reduce(lambda a, b: a * b, n)
x = list(range(N))

stride = n[0] % n[1]
print("stride 1: ", stride)

# Initialize memory
mem = Memory(n[0], n[1])
for i in range(n[1]):
    data_in = x[n[0]*i:n[0]*(i+1)]
    address = (np.arange(n[0]) * 1 + i * stride) % n[1]
    mem.write(data_in, address)
# offset memory rows
for i in range(n[1]):
    address = np.full((n[0],), i) % n[1]
    data_out = mem.read(address)
    data_mem = roll(data_out, i)
    mem.write(data_mem, address)

data = np.uint32(mem.mem).transpose()
print(data)

# Write the data to a mem file
with open('memory_data.mem', 'w') as f:
    for row in data:
        #print(np.uint32(row))
        #print("".join(f"{word:08X}" for word in reversed(row)))
        f.write(" ".join(f"{word:08X}" for word in row) + "\n")

data = []
with open('memory_data.mem', 'r') as f:
    for line in f:
        row = [int(word, 16) for word in line.strip().split()]
        data.append(row)

array_data = np.array(data)
print(array_data)
