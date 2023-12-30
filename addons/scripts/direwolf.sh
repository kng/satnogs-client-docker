#!/bin/bash
# exit if pipeline fails or unset variables
set -eu

# default values
: "${DIREWOLF_FREQ:=144800000}"
: "${DIREWOLF_CONF:=/etc/direwolf.conf}"
: "${SATNOGS_PPM_ERROR:=0}"
: "${SATNOGS_RF_GAIN:=0}"
: "${SATNOGS_APP_PATH:=/tmp/.satnogs}"
: "${SDR_BIN:=rx_fm}"
: "${DIREWOLF_BIN:=direwolf}"
: "${DIREWOLF_SAMPLERATE:=48000}"
DIREWOLF_PID="$SATNOGS_APP_PATH/direwolf.pid"

if [ "${1^^}" == "START" ] && [ "${DIREWOLF_ENABLE^^}" == "YES" ]; then
    echo "Starting direwolf"
    $SDR_BIN -d "$SATNOGS_SOAPY_RX_DEVICE" -a "$SATNOGS_ANTENNA" -p "$SATNOGS_PPM_ERROR" -g "$SATNOGS_RF_GAIN" -f "$DIREWOLF_FREQ" -s "$DIREWOLF_SAMPLERATE" - \
    | $DIREWOLF_BIN -c "$DIREWOLF_CONF" -r "$DIREWOLF_SAMPLERATE" -D 1 -t 0 &
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
