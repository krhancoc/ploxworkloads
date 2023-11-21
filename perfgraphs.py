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

def wrk_data(filename):
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

def get_sqlite_data(data_str):
    entries = data_str.split("\n\n")
    data = {
        "inserts": [],
        "selects": [],
        "updates": [],
        "deletes": [],
    }

    for entry in entries:
        entry = entry.split("\n")
        if len(entry) == 0:
            continue

        if entry[0] == '':
            continue

        key = entry[0].split()[0]
        if key == "total:":
            continue
        data[key].append(float(entry[2].split()[0]))

    data = {k : np.array(v) for k, v in data.items()}
    data = {k : (np.mean(v), np.std(v)) for k, v in data.items()}

    return data


def sqlite_data(filename):
    with open(filename) as f:
        data = "".join(f.readlines())
        data = data.split("PLOX")
        default = data[0]
        default = get_sqlite_data(default)
        plox = data[1][1:]
        plox = get_sqlite_data(plox)

    final_data = {}
    keys = list(default.keys())
    for k in keys:
        final_data_mean = ((default[k][0] - plox[k][0]) / default[k][0]) * 100
        final_data[k] = final_data_mean

    v = np.array(list(final_data.values()))

    return np.mean(v)

def pull_values(data):
    data = data.split()[2:]
    d = {}
    print(data)
    for x in range(0, len(data), 2):
        d[data[x]] = int(data[x+1])

    return d

def breakdown_data(filename):
    final_data = {}
    with open(filename) as f:
        data = "".join(f.readlines())
        data = data.split("\n\n")[:3]

    capcheck_sum = pull_values(data[0])
    syscall_sum = pull_values(data[1])
    counts = pull_values(data[2])
    total = sum(counts.values())

    weight_average = {}
    for k in capcheck_sum.keys():
        # Calculate overhead
        t = (float(capcheck_sum[k]) + float(syscall_sum[k])) / float(syscall_sum[k])
        # Weighted average
        t = t * (float(counts[k]) / float(total))
        weight_average[k] = t
    print(weight_average)

# fig, ax =  plt.subplots(layout="constrained")
#
# rmean, _ = redis_data("out/redis.csv")
# lmean = wrk_data("out/lighttpd.csv")
# nmean = wrk_data("out/nginx.csv")
# mmean = wrk_data("out/memcached.csv")
# smean = sqlite_data("out/sqlite.csv")
#
# labels = ["redis", "lighttpd", "sqlite", "nginx", "memcached"]
# data = [rmean, lmean, smean, nmean, mmean]
# ax.bar(labels, data , label=labels, color=["red"])
# print("Avg Overhead", np.mean(data))
#
# ax.set_ylabel('Overhead (\%)')
#
# fig.savefig("graphs/perf.png")
#

fig, ax = plt.subplots(layout="constrained")
rbreakdown = breakdown_data("out/redis.dtrace")
sbreakdown = breakdown_data("out/sqlite.dtrace")
