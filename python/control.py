
pipeline_delay = 12
ntt_steps = [8, 4, 2]
N = [85, 256, 256]

#0
while not start:
    print("Idle")

for stage in range(3):
    # 1
    for j in range(N[stage]):
        print("PFA/Rader Permutatation, NTT step 1")

    # 2
    for i in range(ntt_steps[stage]):
        for j in range(N[stage]):
            print("NTT step ", i)

    for j in range(N[stage]):
        # 3
        print("Multiply B", "x0 = x0 + X'0")
        # 4
        print("Multiply A", "X'0 = X'0 + x0")

    # 5
    for i in range(ntt_steps[stage]):
        for j in range(N[stage]):
            print("Inv NTT step ", i)

    # 6
    for i in range(pipeline_delay):
        print("Wait for write to memory finished")

