import numpy as np
import math


def is_prime(n):
    if n % 2 == 0 and n > 2:
        return False
    return all(n % i for i in range(3, int(math.sqrt(n)) + 1, 2))


def generate_moduli(factors, count=None):
    # modulus must be prime and (modulus - 1) needs to be divisible by n for n-th root to exist.
    n_bits = int(np.log2(np.prod(factors)))
    candidates = np.prod(factors) * np.arange(1, 2**(32 - n_bits), dtype=np.uint64) + 1

    np_is_prime = np.vectorize(is_prime)
    pbools = np_is_prime(candidates)
    primes = np.extract(pbools, candidates)
    moduli = primes[primes < (2**32-1)]

    return moduli[-count:] if count else moduli


if __name__ == "__main__":
    moduli = generate_moduli([5, 17, 256, 257])
    print(len(moduli), "usable moduli")
    for modulus in moduli:
        print(modulus, " : ", math.ceil(math.log2(modulus)), "bits")
