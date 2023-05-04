import numpy as np
import random

def roll(data, shift):
    return np.roll(data, shift)


lst = []

N = 257

for shift in (0, 1, 75, 255, 256):
    #list_in = np.random.randint(2**32-1, size=(N,), dtype=np.uint32)
    if shift < 76:
        list_in = np.arange(N, dtype=np.uint32)
    else:
        list_in = np.arange(N, dtype=np.uint32) + (2**32-1 - N)
    result = roll(list_in, shift)
    lst.append((list_in, shift, result))

for list_in, shift, result in lst:
    print("#`CLK_PERIOD;")
    print("input_list = {", ", ".join(f"32'd{a}" for a in reversed(list_in)), "};", sep="")
    print(f"shift_amount = 9'd{shift};")
    print("expected = {", ", ".join(f"32'd{a}" for a in reversed(result)), "};", sep="")
    print("@(result);")
    print("result_ok = (expected == result);")
    print("$display(\"result_ok = %x\", result_ok);\n")
