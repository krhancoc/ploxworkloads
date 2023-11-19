#!/usr/bin/env python
import re
import os
import pprint

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
    "getsockopt": 4498,
    "accept": 3901,
    "all": 56791,
}

path = "out"
num_workloads = len(os.listdir(path))

EXTRA_COL = 3

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
    for ls in os.listdir(path):
        full_data[ls] = {}


    reduced_mapping = {}
    for sys,num in MAPPING.items():
        for ls in os.listdir(path):
            p = path + "/" + ls + "/" + str(num) + "/" + filename
            if(os.path.exists(p)):
                reduced_mapping[sys] = num

    i = 0
    for sys,num in reduced_mapping.items():
        for ls in os.listdir(path):
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
        # if sys in TOTALS:
        #     total = TOTALS[sys]
        #     reductions = [round((float(x) / float(total)) * 100) for x in vals if x != "-" and x > 0]
        #     if (len(reductions)):
        #         reductions = round(100 - (sum(reductions) / len(reductions)))
        #         vals.append(reductions)
        #     else:
        #         continue
        # else:
        #     continue

    return full_data

inclusive_data = get_data("kcov-inclusive.log")
exclusive_data = get_data("kcov-exclusive.log")
print("INCLUSIVE")
pprint.pprint(inclusive_data)
# print("EXCLUSIVE")
# pprint.pprint(exclusive_data)

# unique_data_paths = {}
# for name, workload in inclusive_data.items():
#     max_key = max(exclusive_data[name], key=lambda k: exclusive_data[name][k])
#     total = exclusive_data[name][max_key]
#     print(max_key, total)
#     unique_data_paths[name] = {}
#     for sys, num in workload.items():
#         if sys == "all":
#             continue
#         exclusive_num = exclusive_data[name][sys]
#         if num == '-' or num == "N/A":
#             continue
#         unique_data_paths[name][sys] = total - int(exclusive_num)
#
#     total_code = sum([int(x) for x  in unique_data_paths[name].values()])
#     unique_data_paths[name]["TOTAL CODE"] = total_code
#     unique_data_paths[name]["TOTAL"] = total
#
#
#
# pprint.pprint(unique_data_paths)

# total_reduction = round(sum(total_reduction) / len(total_reduction))
# table += "\\bottomrule\n"
# table += "Average Reduction & \multicolumn{" + str(num_workloads + EXTRA_COL - 1) + "}{r}{" + str(total_reduction) +"\\%}\\\\"
#
# table += """
# \\bottomrule
# \\end{tabular}
# """
