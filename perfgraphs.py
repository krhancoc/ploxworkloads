import csv
from pathlib import Path
import os
import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import scienceplots
import numpy as np
plt.style.use(['science', 'ieee'])


REDIS_LOCATION="out/redis.csv"
def extra_data(data_str):
    header = data_str[0].split("\n")[0].split(",")
    all_data = []
    for entry in data_str:
        entry = entry.split("\n")[1:]
        if len(entry) == 0:
            continue

        data = {}
        for e in entry:
            e = e.split(",")
            test_type = e[0][1:-1]
            entry_data = [ float(x[1:-1]) for x in e[1:] ]
            data[test_type] = entry_data

        all_data.append(data)
    
    keys = list(all_data[0].keys())
    final_data = {}
    for k in keys:
        first_row = np.array(all_data[0][k])
        for vals in all_data[1:]:
            first_row = np.sum([first_row, np.array(vals[k])], axis = 0)
        final_data[k] = first_row / len(all_data)
    
    return final_data


def redis_data(filename):
    with open(filename) as f:
        data = "".join(f.readlines())
        data = data.split("PLOX")
        default = data[0].split("\n\n")
        plox = data[1][1:].split("\n\n")

        plox = extra_data(plox)
        default = extra_data(default)
        

    data = []
    keys=list(plox.keys())
    for l in keys:
        data.append(((default[l][0] - plox[l][0]) / default[l][0]) * 100)

    data = np.array(data)
    avg = np.mean(data)
    std = np.std(data)

    return avg, std

def lighttpd_data(filename):
    plox = []
    default = []
    with open(filename) as f:
        data = f.readlines()
        for d in data:
            d = d.split(',')
            if d[0] == "default":
                default.append(float(d[1].strip()))
            else:
                plox.append(float(d[1].strip()))

    plox = np.array(plox) 
    default = np.array(default) 
    pavg = np.mean(plox)
    davg = np.mean(default)
    return ((davg - pavg) / davg) * 100

fig, ax =  plt.subplots(layout="constrained")

rmean_ke, _ = redis_data("out/redis.csv")
rmean, _ = redis_data("out/redis-withoutkevent.csv")
lmean = lighttpd_data("out/lighttpd.csv")

labels = ["redis+ke", "redis-ke", "lighttpd"]
ax.bar(labels, [rmean_ke, rmean, lmean], label=labels, color=["red"])

ax.set_ylabel('Overhead (\%)')

fig.savefig("graphs/perf.png")
