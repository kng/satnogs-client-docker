#!/bin/bash

# default values
if [ -z "$DIREWOLF_FREQ" ]; then
    #DIREWOLF_FREQ=144390000
    DIREWOLF_FREQ=144800000
fi
if [ -z "$DIREWOLF_CONF" ]; then
    DIREWOLF_CONF=/etc/direwolf.conf
fi
if [ -z "$SATNOGS_PPM_ERROR" ]; then
    SATNOGS_PPM_ERROR=0
fi
if [ -z "$SATNOGS_RF_GAIN" ]; then
    SATNOGS_RF_GAIN=0
fi

SDR_BIN="rx_fm"
DIREWOLF_BIN="direwolf"
DIREWOLF_PID="/tmp/.satnogs/direwolf.pid"
SAMPLERATE="48000"

if [ "${1^^}" == "START" ] && [ "${DIREWOLF_ENABLE^^}" == "YES" ]; then
    echo "Starting direwolf"
    $SDR_BIN -d "$SATNOGS_SOAPY_RX_DEVICE" -a "$SATNOGS_ANTENNA" -p "$SATNOGS_PPM_ERROR" -g "$SATNOGS_RF_GAIN" -f "$DIREWOLF_FREQ" -s "$SAMPLERATE" - \
    | $DIREWOLF_BIN -c "$DIREWOLF_CONF" -r "$SAMPLERATE" -D 1 -l "$HOME" -t 0 &
    echo $! > "$DIREWOLF_PID"
fi

if [ "${1^^}" == "STOP" ]; then
   if [ -f "$DIREWOLF_PID" ]; then
       echo "Stopping direwolf"
       kill "$(cat "$DIREWOLF_PID")"
       killall "$SDR_BIN"
       rm -f "$DIREWOLF_PID"
   fi
fi
