#!/usr/bin/env python3
from sys import argv

# This script takes two arguments: {{BAUD}} {{SCRIPT_NAME}}
# and tries to figure out the IQ sample rate


# from satnogs_gr-satellites/find_samp_rate.py
def find_samp_rate(baudrate, script="", sps=4, audio_samp_rate=48000):
    try:
        baudrate = int(float(baudrate))
    except ValueError:
        baudrate = 9600
    if baudrate < 1:
        baudrate = 9600
    if "_bpsk" in script:
        return find_decimation(baudrate, 2, audio_samp_rate, sps) * baudrate
    elif "_fsk" in script:
        return max(4, find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
    elif "_sstv" in script:
        return 4 * 4160 * 4
    elif "_qubik" in script:
        return max(4, find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
    elif "_apt" in script:
        return 4 * 4160 * 4
    elif "_ssb" in script:
        return find_decimation(baudrate, 2, audio_samp_rate, sps) * baudrate
    else:  # cw, fm, afsk, etc...
        return audio_samp_rate


# from gr-satnogs/python/utils.py
def find_decimation(baudrate, min_decimation=4, audio_samp_rate=48e3, multiple=2):
    while min_decimation * baudrate < audio_samp_rate:
        min_decimation = min_decimation + 1
    if min_decimation % multiple:
        min_decimation = min_decimation + multiple - min_decimation % multiple
    return min_decimation


if __name__ == "__main__":
    try:
        baud_rate = int(float(argv[1]))
    except (ValueError, IndexError):
        baud_rate = 9600
    try:
        script_name = argv[2]
    except (ValueError, IndexError):
        script_name = ""
    print(find_samp_rate(baud_rate, script_name))
