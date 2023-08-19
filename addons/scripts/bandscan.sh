#!/bin/bash

# default values
if [ -z "$BANDSCAN_FREQ" ]; then
    BANDSCAN_FREQ=401000000
fi
if [ -z "$BANDSCAN_SAMPLERATE" ]; then
    BANDSCAN_SAMPLERATE="$SATNOGS_RX_SAMP_RATE"
fi
if [ -z "$BANDSCAN_DIR" ]; then
    BANDSCAN_DIR=/srv/bandscan
fi
if [ -z "$SATNOGS_PPM_ERROR" ]; then
    SATNOGS_PPM_ERROR=0
fi
if [ -z "$SATNOGS_RF_GAIN" ]; then
    SATNOGS_RF_GAIN=0
fi

BANDSCAN_PID="/tmp/.satnogs/bandscan.pid"
BANDSCAN_BIN="rx_sdr"
OUTPUT_FORMAT="CF32"
INPUT_FORMAT="float"

if [ "${1^^}" == "START" ] && [ "${BANDSCAN_ENABLE^^}" == "YES" ]; then
    echo "Starting bandscan"
    DAY=$(date -Idate)
    SAVEDIR="$BANDSCAN_DIR/$BANDSCAN_FREQ/$DAY"
    mkdir -p "$SAVEDIR" "$(dirname "$BANDSCAN_PID")"
    INDEX=$(find "$SAVEDIR" -mindepth 1 -maxdepth 1 -type f | wc -l)
    $BANDSCAN_BIN -d "$SATNOGS_SOAPY_RX_DEVICE" -a "$SATNOGS_ANTENNA" -p "$SATNOGS_PPM_ERROR" -g "$SATNOGS_RF_GAIN" -s "$BANDSCAN_SAMPLERATE" -f "$BANDSCAN_FREQ" -F "$OUTPUT_FORMAT" - \
    | rffft -q -f "$BANDSCAN_FREQ" -s "$BANDSCAN_SAMPLERATE" -F "$INPUT_FORMAT" -c 50 -t 1 -p "$SAVEDIR" -o "$DAY" -S "$INDEX" &
    echo $! > "$BANDSCAN_PID"
fi

if [ "${1^^}" == "STOP" ]; then
   if [ -f "$BANDSCAN_PID" ]; then
       echo "Stopping bandscan"
       kill "$(cat "$BANDSCAN_PID")"
       rm -f "$BANDSCAN_PID"
   fi
fi

