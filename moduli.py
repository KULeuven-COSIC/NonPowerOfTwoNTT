import numpy as np
import math

def is_prime(n):
    if n % 2 == 0 and n > 2:
        return False
    return all(n % i for i in range(3, int(math.sqrt(n)) + 1, 2))

a = 257 * 17 * 5 * 3 * 256 * np.arange(1, 256, dtype=np.uint64) + 1

foo = np.vectorize(is_prime)
pbools = foo(a)
primes = np.extract(pbools, a)
print(primes[primes < (2**32-1)])

