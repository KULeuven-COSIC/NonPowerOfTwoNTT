from moduli import moduli
from util import util
import random
import math
random.seed(0)


def butterfly(a, b, wn, m):
    b = (b * wn) % m
    print("BxW", b)
    ar = (a + b) % m
    br = (a - b) % m
    return ar, br


lst = []

for i in range(5):
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
    w = random.randint(0, m)
    ar, br = butterfly(a, b, w, m)
    BxW = (b * w) % m
    wR = (w * R) % m
    lst.append((a, b, wR, m, ar, br, BxW))


for a, b, wR, m, ar, br, BxW in lst:
    print(f"perform_multiply('d{b}, 'd{wR}, 'd{m});")
    print(f"perform_butterfly('d{a}, 'd{b}, 'd{wR}, 'd{m});")

for a, b, wR, m, ar, br, BxW in lst:
    print(f"check_multiply_result('d{BxW});")
    print(f"check_butterfly_result('d{ar}, 'd{br});")

exit(0)

lst = []

for i in range(5):
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
    w = random.randint(0, m)
    ar = (a * w) % m
    wR = (w * R) % m
    lst.append((a, wR, m, ar))


for a, wR, m, ar in lst:
    print(f"perform_multiply('d{a}, 'd{wR}, 'd{m});")

for a, wR, m, ar in lst:
    print(f"check_multiply_result('d{ar});")
