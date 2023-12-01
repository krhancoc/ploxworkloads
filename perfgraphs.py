import csv
from decimal import Decimal
from pathlib import Path
import os
import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
import scienceplots
import numpy as np
plt.style.use(['science', 'ieee'])

def extra_data(data_str):
    if data_str is None:
        return None

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
        try:
            ploxopt = data[2][1:].split("\n\n")
        except:
            ploxopt = None

        plox = extra_data(plox)
        default = extra_data(default)
        ploxopt = extra_data(ploxopt)
        

    data = []
    dataopt = []
    keys=list(plox.keys())
    for l in keys:
        data.append(((default[l][0] - plox[l][0]) / default[l][0]) * 100)
        if ploxopt is not None:
            dataopt.append(((default[l][0] - ploxopt[l][0]) / default[l][0]) * 100)
    print(data, dataopt)

    return np.mean(data), np.mean(dataopt)

def wrk_data(filename):
    plox = []
    default = []
    ploxopt = []
    with open(filename) as f:
        data = f.readlines()
        for d in data:
            d = d.split(',')
            if d[0] == "default":
                default.append(float(d[1].strip()))
            if d[0] == "plox":
                plox.append(float(d[1].strip()))
            else:
                ploxopt.append(float(d[1].strip()))

    plox = np.array(plox) 
    default = np.array(default) 
    pavg = np.mean(plox)
    poavg = np.mean(ploxopt)
    davg = np.mean(default)
    return ((davg - pavg) / davg) * 100, ((davg - poavg) / davg) * 100

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

def last_res(results):
    return int(results.split("\n")[-2])

def nginx_res(results):
    return float(results.split("\n")[-4].split()[0])

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
    total_c = sum([v[0] for v in data.values()])
    total_s = sum([v[1] for v in data.values()])

    checkactual = [ ((v[0] / (v[1] + v[0])) * 100)  for k, v in data.items() ]
    checkd = [ ((v[0] / (v[1] + v[0])) * 100) * (v[0] / total_c) for k, v in data.items() ]
    sysd = [ ((v[1] / (v[1] + v[0])) * 100) * (v[0] / total_c) for k, v in data.items() ]

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
    ax.set_yscale('log')
    bottom = np.zeros(len(labels))

    matplotlib.rcParams["legend.frameon"] = True
     
    for name, weight_count in weight_counts.items():
        bars = ax.bar(labels, weight_count, width, label=name, bottom=bottom, color=colors[name])
        bottom += weight_count
        if name == "Capability Check":
            ax.bar_label(bars,  ['%.3f\\%%' % x for x in checkactual], label_type='edge')

    ax.set_ylim(ax.get_ylim()[0], 110.)
    ax.set_title("{} - {:10.1f} Syscalls/transaction".format(title, spt))
    ax.set_ylabel("Percentage (\%)")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=-60)
    ax.legend()
    title = "".join(title.lower().split())
    fig.savefig("graphs/{}.svg".format(title))
    fig.savefig("graphs/{}.pgf".format(title))
        
fig, ax =  plt.subplots(layout="constrained")

rmean, romean = redis_data("out/redis.csv")
lmean, lomean = wrk_data("out/lighttpd.csv")
nmean, nomean = wrk_data("out/nginx.csv")
mmean, momean = wrk_data("out/memcached.csv")
smean, somean = sqlite_data("out/sqlite.csv")

sc_redis, _ = redis_data("out/redis-seccomp.csv")
sc_light, _ = wrk_data("out/lighttpd-seccomp.csv")
sc_nginx, _ = wrk_data("out/nginx-seccomp.csv")
sc_memcached, _ = wrk_data("out/memcached-seccomp.csv")
print(sc_redis, sc_light, sc_nginx, sc_memcached)

labels = ["Redis+DC", "Redis*+DC", "Redis+S", "lighttpd+DC", "lighttpd*+DC", "lighttpd+S", "nginx+DC", "nginx*+DC", "nginx+S", "memcached+DC", "memcached*+DC", "memcached+S", ]
data = [rmean, romean, sc_redis, lmean, lomean, sc_light, nmean, nomean, sc_nginx, mmean, momean, sc_memcached]
bars = ax.bar(labels, data , label=labels, color=["#B2BEB5","#BFBFFF", "#B2FFB5", "#B2BEB5", "#BFBFFF", "#B2FFB5","#B2BEB5", "#BFBFFF", "#B2FFB5", "#B2BEB5","#BFBFFF", "#B2FFB5"])
ax.legend(bars[:3], ["PLOX", "PLOX Optimized", "Seccomp"])

ax.set_xticklabels(ax.get_xticklabels(), rotation=-90)

data = [romean, lomean, nomean, momean]
print("Avg Overhead PLOX", np.mean(data))

data = [sc_redis, sc_light, sc_nginx, sc_memcached]
print("Avg Overhead Seccomp", np.mean(data))

ax.set_ylabel('Overhead (\%)')

fig.savefig("graphs/perf.svg")
fig.savefig("graphs/perf.pgf")

breakdown_graph("redis", breakdown_data("out/redis.dtrace", last_res))
breakdown_graph("sqlite", breakdown_data("out/sqlite.dtrace", sqlite_res))
breakdown_graph("memcached", breakdown_data("out/memcached.dtrace", last_res))
breakdown_graph("nginx", breakdown_data("out/nginx.dtrace", last_res))
breakdown_graph("lighttpd", breakdown_data("out/lighttpd.dtrace", last_res))
