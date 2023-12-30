#!/usr/bin/env python3
from sys import argv

# This script takes two arguments: {{BAUD}} {{SCRIPT_NAME}}
# and tries to figure out the IQ sample rate


# from satnogs_gr-satellites/find_samp_rate.py
def find_samp_rate(baudrate, script='satnogs_fm.py', sps=4, audio_samp_rate=48000):
    if '_bpsk' in script:
        return find_decimation(baudrate, 2, audio_samp_rate, sps) * baudrate
    elif '_fsk' in script:
        return max(4, find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
    elif '_sstv' in script:
        return 4 * 4160 * 4
    elif '_qubik' in script:
        return max(4, find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
    elif '_apt' in script:
        return 4 * 4160 * 4
    else:  # cw, fm, afsk, etc...
        return audio_samp_rate


# from gr-satnogs/python/utils.py
def find_decimation(baudrate, min_decimation=4, audio_samp_rate=48e3, multiple=2):
    while min_decimation * baudrate < audio_samp_rate:
        min_decimation = min_decimation + 1
    if min_decimation % multiple:
        min_decimation = min_decimation + multiple - min_decimation % multiple
    return min_decimation


if __name__ == '__main__':
    if len(argv) == 2:
        print(find_samp_rate(int(float(argv[1]))))
    elif len(argv) == 3:
        print(find_samp_rate(int(float(argv[1])), argv[2]))
    else:
        print(f"Usage: {argv[0]} <baudrate> [script_name]\n"
              "From SatNOGS: {{BAUD}} {{SCRIPT_NAME}}")
