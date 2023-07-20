from util import util
import numpy as np

N = 12
m = 37
N_inv = util.fast_exp(N, m-2, m)
p_root = util.principal_root_of_unity(N, m)
p_root_inv = util.fast_exp(p_root, m-2, m)
x = list(range(N))

print([util.fast_exp(p_root, i, m) for i in range(N)])
print([util.fast_exp(p_root_inv, i, m) for i in range(N)])

X = util.ntt(x, p_root, m)
print(N, N_inv, (N*N_inv) % m)
print([(e * N) % m for e in x])
print(x)
print(X)
X_rev = [X[0]] + X[-1:0:-1]
print(util.ntt(X, p_root_inv, m))
print(util.ntt(X_rev, p_root, m))
