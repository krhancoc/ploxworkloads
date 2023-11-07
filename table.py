#!/usr/bin/env python
import re
import os

MAPPING = {}

def get_value(path):
    with open(path) as f:
        data = f.readlines()[-2].split()[-1]
        return int(data)



with open("/usr/include/sys/syscall.h") as f:
    data = f.readlines()
    for line in data:
        sys_re = r"\#define\sSYS_"
        match = re.search(sys_re, line)
        if (match):
            line = line.split()
            MAPPING[line[1].split("_")[1]] = int(line[2])

TOTALS = {
    "mmap": 4800,
    "recv": 4280,
    "send": 7162,
    "read": 18788,
    "open": 12990,
    "setsockopt": 7569,
    "connect": 9792,
    "close": 7480,
    "fstatat": 5545,
    "ioctl": 13097,
    "write": 12553,
    "close": 7480,
    "fcntl": 6070,
    "stat": 5545,
    "lseek": 5815,
    "truncate": 11539,
    "sendmsg": 14173,
    "recvmsg": 4380,
    "kevent": 4044,
    "bind": 10197,
    "listen": 1336,
    "accept4": 1379,
    "getsockopt": 3743,
}

path = "out"
num_workloads = len(os.listdir(path))

EXTRA_COL = 3
table = "\\begin{tabular}{@{}" + 'l' * (num_workloads + EXTRA_COL) + "@{}}\n"
table += "\\toprule\n"

header = "Syscall Name,"
table += "\\textbf{System Call} & "  
for ls in os.listdir(path):
    header += ls + ","
    table += "\\textbf{" + ls + "} & "
table += "\\textbf{Total} & \\textbf{Avg Reduction}\\\\\n"
header += "Total"
table += "\\midrule\n"

#print(header)

reduced_mapping = {}
for sys,num in MAPPING.items():
    for ls in os.listdir(path):
        p = path + "/" + ls + "/" + str(num) + "/" + "analysis.txt"
        if(os.path.exists(p)):
            reduced_mapping[sys] = num


csv = header + "\n"
i = 0
total_reduction = []
for sys,num in reduced_mapping.items():
    line = "\\code{" + sys + "} & "
    vals = []
    for ls in os.listdir(path):
        p = path + "/" + ls + "/" + str(num) + "/" + "analysis.txt"
        if(os.path.exists(p)):
            value = get_value(p)
            if (value > 0):
                vals.append(value)
        else:
            value = "N/A"
        line += str(value) + " & "
    if sys in TOTALS:
        total = TOTALS[sys]
        reductions = [round((float(x) / float(total)) * 100) for x in vals if x > 0]
        if (len(reductions)):
            reductions = round(100 - (sum(reductions) / len(reductions)))
            line += str(TOTALS[sys]) + " & " + str(reductions) + "\\% \\\\\n"
            total_reduction.append(reductions)
        else:
            continue
    else:
        continue

    if ((i % 2) == 0):
        line += "\\rowcolor[HTML]{EFEFEF}\n"
    i += 1
    table += line

total_reduction = round(sum(total_reduction) / len(total_reduction))
table += "\\bottomrule\n"
table += "Average Reduction & \multicolumn{" + str(num_workloads + EXTRA_COL - 1) + "}{c}{" + str(total_reduction) +"\\%}\\\\"

table += """
\\bottomrule
\\end{tabular}
"""
print(table)
