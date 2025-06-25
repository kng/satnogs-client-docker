#!/bin/bash
# exit if pipeline fails or unset variables
set -eu

# Launch with: {command} {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
CMD="$1"     # $1 [start|stop]
ID="$2"      # $2 observation ID
#FREQ="$3"    # $3 frequency
TLE="$4"     # $4 used tle's
DATE="$5"    # $5 timestamp Y-m-dTH-M-S
BAUD="$6"    # $6 baudrate
SCRIPT="$7"  # $7 script name, satnogs_bpsk.py

# default values
: "${METEOR_NORAD:=57166 59051}"
: "${UDP_DUMP_PORT:=57356}"
: "${SATNOGS_APP_PATH:=/tmp/.satnogs}"
: "${SATNOGS_OUTPUT_PATH:=/tmp/.satnogs/data}"

PRG="Meteor demod+decode"
METEOR_PID="$SATNOGS_APP_PATH/meteor_$SATNOGS_STATION_ID.pid"
IMAGE="$SATNOGS_OUTPUT_PATH/data_${ID}_${DATE}.png"
SATNAME=$(echo "$TLE" | jq .tle0 | sed -e 's/ /_/g' | sed -e 's/[^A-Za-z0-9._-]//g')
NORAD=$(echo "$TLE" | jq .tle2 | awk '{print $2}')

if [ "${CMD^^}" == "START" ]; then
  if [ -z ${METEOR_NORAD+x} ] || [[ " ${METEOR_NORAD} " =~ .*\ ${NORAD}\ .* ]]; then
    echo "$PRG: $ID, Norad: $NORAD, Name: $SATNAME, Script: $SCRIPT"
    if [ -z "$UDP_DUMP_HOST" ]; then
      echo "Warning: UDP_DUMP_HOST not set, no data will be sent to the demod"
    fi
    SAMP=$(find_samp_rate.py "$BAUD" "$SCRIPT")
    if [ -z "$SAMP" ]; then
      SAMP=144000
      echo "WARNING: find_samp_rate.py did not return valid sample rate!"
    fi
    SYMRATE=72000
    INTERLACE=""
# The following is experimental, has only been used during commissioning
#   SYMRATE=$((${BAUD%.*} * 2))
#   if [ ${SYMRATE} == 80000 ]; then
#     INTERLACE="--int"
#   else
#     INTERLACE=""
#   fi
    ( udp2ishort.py -p "$UDP_DUMP_PORT" & echo $! > "$METEOR_PID" ) | \
    meteor_demod --batch --quiet -O 8 -f 128 -s "$SAMP" -r "$SYMRATE" -m oqpsk --bps 16 --stdout - | \
    meteor_decode --batch --quiet "$INTERLACE" --diff -a 65,65,64 -o "$IMAGE" - &
  fi
fi

if [ "${CMD^^}" == "STOP" ]; then
  if [ -f "$METEOR_PID" ]; then
    kill "$(cat "$METEOR_PID")"
    rm -f "$METEOR_PID"
  fi
fi
