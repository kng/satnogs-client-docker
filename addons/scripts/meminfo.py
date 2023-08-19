#!/usr/bin/env python3
import psutil
import sys

if len(sys.argv) != 2:
    print('supply pid to connect')
    exit(-1)
p = psutil.Process(int(sys.argv[1]))
print(p.memory_info())
for i in p.memory_maps():
    print(i)
