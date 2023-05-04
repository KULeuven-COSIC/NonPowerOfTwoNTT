from moduli import moduli
from util import util
import random
import math
random.seed(0)

lst = []

for i in range(10):
    m = int(moduli[-1]) #int(random.choice(moduli))
    K = 32
    n = 128
    w = 8 #int(math.log2(2*n))
    L = 4 #int(math.ceil(K/w))
    R = 2**(L*w)
    R_inv = util.fast_exp(R, m - 2, m)
    print("w = ", w)
    print("L = ", L)
    print("R = ", R, (R * R_inv) % m)
    print("m = ", m)
    a = random.randint(0, m)
    b = random.randint(0, m)
    c = (a * b) % m
    cR_inv = (c * R_inv) % m
    print(c)
    print(cR_inv)
    lst.append((a, b, m, cR_inv))

for a, b, m, cR_inv in lst:
    print(f"perform_multiply('d{a}, 'd{b}, 'd{m});")

for a, b, m, cR_inv in lst:
    print(f"check_result('d{cR_inv});")
