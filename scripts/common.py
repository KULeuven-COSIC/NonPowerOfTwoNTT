import numpy as np
from math import sqrt


def find_factors(n):
    factors = set()
    for i in range(2, int(sqrt(n)) + 1):
        if n % i == 0:
            factors.add(i)
            factors.add(n // i)
    return factors


def is_primitive_root(g, p):
    factors = find_factors(p - 1)
    for factor in factors:
        if pow(g, (p - 1) // factor, p) == 1:
            return False
    return True


def primitive_root(p):
    for g in range(2, p):
        if is_primitive_root(g, p):
            return g
    return None


def root_of_unity(order, p):
    g = primitive_root(p)
    return pow(g, (p - 1) // order, p)


def ntt(x, p_root, m):
    """Naive NTT implementation"""
    # Compute twiddle factors
    e = np.arange(x.size)
    b = p_root
    w = np.where(e & 1, b, 1).astype(np.uint64)
    while np.any(e):
        np.right_shift(e, 1, out=e)
        b = pow(b, 2, m)
        mask = (e & 1).astype(bool)
        w[mask] = (w[mask] * b) % m

    # Compute NTT
    X = np.zeros_like(x)
    wn = np.ones_like(x)
    temp = np.zeros_like(x)
    for n in range(x.size):
        np.multiply(wn, x[n], out=temp)
        np.mod(temp, m, out=temp)
        np.add(X, temp, out=X)
        np.multiply(wn, w, out=temp)
        np.mod(temp, m, out=wn)
    np.mod(X, m, out=X)
    return X
