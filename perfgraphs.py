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

def calculate_sqlite_overhead(default, plox):
    final_data = {}
    keys = list(default.keys())
    for k in keys:
        final_data_mean = ((default[k][0] - plox[k][0]) / default[k][0]) * 100
        final_data[k] = final_data_mean

    return np.array(list(final_data.values()))


def sqlite_data(filename):
    with open(filename) as f:
        data = "".join(f.readlines())
        data = data.split("PLOX")
        default = data[0]
        default = get_sqlite_data(default)
        plox = data[1][1:]
        ploxopt = data[2][1:]
        plox = get_sqlite_data(plox)
        ploxopt = get_sqlite_data(ploxopt)

    plox = calculate_sqlite_overhead(default, plox)
    ploxopt = calculate_sqlite_overhead(default, ploxopt)

    return np.mean(plox), np.mean(ploxopt)

def pull_values(data):
    data = data.split()[2:]
    d = {}
    fs = 0
    for x in range(0, len(data), 2):
        d[data[x]] = float(data[x+1])
        fs += float(data[x+1])
    #d["total"] = fs

    return d

def memcached_res(results):
    results = results.split("\n")[-2].split()
    tps = float(results[6])
    time = float(results[2][:-1])
    return time * tps

# Every operation is done 50k times
def redis_res(results):
    return len(results.split("\n")[2:-1]) * 50000

def sqlite_res(results):
    results = results[1:-1].split("\n\n")
    sections = len(results)

    # One section is just the totals
    amount = int(results[0].split()[1][1:-2]) - 1
    return sections * amount


def breakdown_data(filename, func):
    final_data = {}
    with open(filename) as f:
        data = "".join(f.readlines())
        data = data.split("RESULTS")
        totaltransactions = func(data[1])
        data = data[0].split("\n\n")[:3]

    capcheck_sum = pull_values(data[0])
    syscall_sum = pull_values(data[1])
    counts = pull_values(data[2])
    total = sum(counts.values())

    final_data = {k: [capcheck_sum[k], syscall_sum[k], counts[k]] for k in capcheck_sum.keys() }

    return [final_data, total / totaltransactions]

def breakdown_graph(title, data):
    spt = data[1]
    data = data[0]
    labels = list(data.keys())
    total = sum([v[2] for v in data.values()])
    checkd = [ ((v[0] / (v[1] + v[0])) * 100) for k, v in data.items() ]
    sysd = [ ((v[1] / (v[1] + v[0])) * 100) for k, v in data.items() ]

    width = 0.5
    weight_counts = {
            "System call": sysd,
            "Capability Check": checkd,
    }
    colors = {
            "Capability Check": "#F8DE7E",
            "System call": "#B2BEB5",
    }


    fig, ax = plt.subplots(layout="constrained")
    bottom = np.zeros(len(labels))

    matplotlib.rcParams["legend.frameon"] = True
    
    for name, weight_count in weight_counts.items():
        p = ax.bar(labels, weight_count, width, label=name, bottom=bottom, color=colors[name])
        bottom += weight_count
    ax.set_title("{} - {:10.1f} Syscalls/transaction".format(title, spt))
    ax.set_ylim([0., 100.])
    ax.set_ylabel("Percentage (\%)")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=-60)
    ax.legend(loc="lower right")
    title = "".join(title.lower().split())
    fig.savefig("graphs/{}.pgf".format(title))
        
fig, ax =  plt.subplots(layout="constrained")

rmean, _ = redis_data("out/redis.csv")
lmean = wrk_data("out/lighttpd.csv")
nmean = wrk_data("out/nginx.csv")
mmean = wrk_data("out/memcached.csv")
smean, somean = sqlite_data("out/sqlite.csv")

labels = ["redis", "lighttpd", "sqlite", "sqlite-rw", "nginx", "memcached"]
data = [rmean, lmean, smean, somean, nmean, mmean]
ax.bar(labels, data , label=labels, color=["#B2BEB5"])
print("Avg Overhead", np.mean(data))

ax.set_ylabel('Overhead (\%)')

fig.savefig("graphs/perf.svg")

breakdown_graph("redis", breakdown_data("out/redis.dtrace", redis_res))
breakdown_graph("sqlite", breakdown_data("out/sqlite.dtrace", sqlite_res))
breakdown_graph("memcached", breakdown_data("out/memcached.dtrace", memcached_res))
