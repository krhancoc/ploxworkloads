d = {}
with open("out") as f:
    for l in f.readlines():
        sys = l.split()[1].split("(")[0]
        if sys in d:
            continue
        if sys.startswith("+"):
            continue
        if sys.startswith("<"):
            continue
        if sys.startswith("-"):
            continue

        d[sys] = l

for sys, l in d.items():
    print("Allow({}),".format(sys))
