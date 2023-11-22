#!/usr/bin/env python
import re
import os
import pprint
import numpy as np

MAPPING = {}

def get_value(path):
    with open(path) as f:
        return len(f.readlines())



with open("/usr/include/sys/syscall.h") as f:
    data = f.readlines()
    for line in data:
        sys_re = r"\#define\sSYS_"
        match = re.search(sys_re, line)
        if (match):
            line = line.split()
            MAPPING[line[1].split("_")[1]] = int(line[2])

MAPPING["all"] = 9999

TOTALS = {
    "read": 12185,
    "write": 12388,
    "open": 12528,
    "recvmsg": 11589,
    "sendmsg": 11589,
    "accept": 12864,
    "fcntl": 11914,
    "select": 11809,
    "socket": 13453,
    "connect": 12644,
    "bind": 12576,
    "setsockopt": 13235,
    "listen": 12802,
    "getsockopt": 12209,
    "sendto": 12864,
    "poll": 12696,
    "mmap": 13166,
    "truncate": 12903,
    "ftruncate": 12844,
    "accept4": 12939,
    "fstatat": 13112,
    "kevent": 12042
}

path = "out"
# A system call has some unique code blocks plus shared blocks. To determine what is shared
# You need to get the total amount of code blocks during the runtime, then subtract all the unique
# code paths of every system call of the workload. This is done by getting the total amount of codeblock
# minus that specific system call.

# Formula should be Shared = TOTAL - (SUM(UNIQUE SYS_CALL))

# To determine how much code was debloated a similar approach should be done with syzkaller
# Shared = (PROGRAM KERNEL CALLS) - (SUM (UNIQUE GLOBAL SYS_CALL))
# You can say for certain that coarse grained debloating techniques are able to reduce all unique code
# paths.

# To determine how much coarse grained debloating you take
# TOTAL KERNEL CALL - (SUM UNIQUE SYS CALL) - (SHARED)
def get_data(filename):
    full_data = {}
    workloads = []
    for ls in os.listdir(path):
        if (os.path.isdir(path + "/" + ls)):
            workloads.append(ls)
            full_data[ls] = {}


    reduced_mapping = {}
    for sys,num in MAPPING.items():
        for ls in workloads:
            p = path + "/" + ls + "/" + str(num) + "/" + filename
            if(os.path.exists(p)):
                reduced_mapping[sys] = num

    i = 0
    for sys,num in reduced_mapping.items():
        for ls in workloads:
            try:
                p = path + "/" + ls + "/" + str(num) + "/" + filename 
                if(os.path.exists(p)):
                    value = get_value(p)
                    if (value == 0):
                        value = "-"
                else:
                    value = "N/A"
                full_data[ls][sys] = value
            except Exception as e:
                print(p, e)
                exit(0)

    return full_data

def create_header(row):
    header = "\\begin{{tabular}}{{@{{}}{}r@{{}}}}\n".format("l" * (len(row) -1))
    header += "\\toprule\n"
    row = ["\\textbf{{{}}}".format(h) for h in row]
    header += " & ".join(row)
    header += "\\\\\n"
    header += "\\midrule\n"
    return header

def create_row(row):
    row = [ str(s) for s in row ]
    return " & ".join(row) + " \\\\\n"
    

def create_coverage_table(data):
    workloads = list(data.keys())
    header = ["System Call"] + list(workloads) + ["Total", "Average Reduction (\\%)"]
    table = create_header(header)
    syscalls = list(TOTALS.keys())
    rows = []
    avg = []
    for s in syscalls:
        row = []
        for w in workloads:
            row.append(data[w][s])
        
        reduction = []
        for r in row:
            try:
                r = (1 - (float(r) / float(TOTALS[s]))) * 100
                reduction.append(r)
            except:
                continue
        
        if len(reduction):
            reduction = np.mean(reduction)
            avg.append(reduction)
            code_block = "\\code{{{}}}".format(s)
            row = [code_block] + row + [str(TOTALS[s]),"%.1f" % (reduction, )]
            rows.append(row)

    for i, r in enumerate(rows):
        table += create_row(r)
        if (i % 2) == 0:
            table += "\\rowcolor[HTML]{EFEFEF}\n"

    avg = "%.1f" % (np.mean(avg), )
    table += "\\bottomrule\n"
    table += "Average Reduction & \\multicolumn{{{}}}{{r}}{{{}\\%}}\\\\\n".format(len(header) - 1, avg)
    table += "\\bottomrule\n"
    table += "\\end{tabular}\n"

    return table


inclusive_data = get_data("kcov-inclusive.log")

table = create_coverage_table(inclusive_data)
print(table)

