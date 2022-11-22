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

BANDSCAN_PID="/tmp/.satnogs/bandscan.pid"
BANDSCAN_BIN="rx_sdr"

if [ "${1^^}" == "START" ] && [ "${BANDSCAN_ENABLE^^}" == "YES" ]; then
    echo "Starting bandscan"
    DAY=$(date -Idate)
    SAVEDIR="$BANDSCAN_DIR/$BANDSCAN_FREQ/$DAY"
    mkdir -p "$SAVEDIR"
    INDEX=$(find "$SAVEDIR" -mindepth 1 | wc -l)
    $BANDSCAN_BIN -d "$SATNOGS_SOAPY_RX_DEVICE" -a "$SATNOGS_ANTENNA" -p "$SATNOGS_PPM_ERROR" -g "$SATNOGS_RF_GAIN" -s "$BANDSCAN_SAMPLERATE" -f "$BANDSCAN_FREQ" -F CF32 - | rffft -q -f "$BANDSCAN_FREQ" -s "$BANDSCAN_SAMPLERATE" -F float -c 50 -t 1 -p "$SAVEDIR" -o "$DAY" -S "$INDEX" &
    echo $! > "$BANDSCAN_PID"
fi