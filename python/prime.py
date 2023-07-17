import math

def is_prime(n):
    if n <= 1:
        return False
    if n <= 3:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    while i * i <= n:
        if n % i == 0 or n % (i + 2) == 0:
            return False
        i += 6
    return True

def get_primes(N, count):
    primes = []
    k = 1
    while len(primes) < count:
        candidate = k * N + 1
        if is_prime(candidate):
            primes.append(candidate)
        k += 1
    return primes

N = int(input("Enter a number (N): "))
count = 20

primes = get_primes(N, count)
last_prime = primes[-1]
log_value = math.log2(last_prime)

print(f"The first 20 primes of the form k*N + 1 where N={N} is:")
print(primes)
print(f"The 2log of the last prime ({last_prime}) is: {log_value}")