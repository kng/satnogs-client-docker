#!/bin/bash
# {command} {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}

CMD="$1"     # $1 [start|stop]
ID="$2"      # $2 observation ID
#FREQ="$3"    # $3 frequency
TLE="$4"     # $4 used tle's
DATE="$5"    # $5 timestamp Y-m-dTH-M-S
BAUD="$6"    # $6 baudrate
SCRIPT="$7"  # $7 script name, satnogs_bpsk.py

# default values
if [ -z "$METEOR_NORAD" ]; then
  METEOR_NORAD="57166"
fi
if [ -z "$UDP_DUMP_PORT" ]; then
  UDP_DUMP_PORT=57356
fi

PRG="Meteor demod+decode"
TMP="/tmp/.satnogs"
DATA="$TMP/data"   # SATNOGS_OUTPUT_PATH
METEOR_PID="$TMP/meteor_$SATNOGS_STATION_ID.pid"
IMAGE="$TMP/meteor_${ID}.png"
SATNAME=$(echo "$TLE" | jq .tle0 | sed -e 's/ /_/g' | sed -e 's/[^A-Za-z0-9._-]//g')
NORAD=$(echo "$TLE" | jq .tle2 | awk '{print $2}')

if [ "${CMD^^}" == "START" ]; then
  if [ -z ${METEOR_NORAD+x} ] || [[ ${METEOR_NORAD} =~ ${NORAD} ]]; then
    echo "$PRG: $ID, Norad: $NORAD, Name: $SATNAME, Script: $SCRIPT"
    if [ -z "$UDP_DUMP_HOST" ]; then
      echo "Warning: UDP_DUMP_HOST not set, no data will be sent to the demod"
    fi
    SAMP=$(find_samp_rate.py "$BAUD" "$SCRIPT")
    if [ -z "$SAMP" ]; then
      SAMP=72000
      echo "WARNING: find_samp_rate.py did not return valid sample rate!"
    fi

    nc -ul "$UDP_DUMP_PORT" | \
    meteor_demod --batch --quiet -O 8 -f 128 -s "$SAMP" -m oqpsk --bps 16 --stdout - | \
    meteor_decode --batch --quiet --diff -a 65,65,64 -o "$IMAGE" - &
    echo $! > "$METEOR_PID"
  fi
fi

if [ "${CMD^^}" == "STOP" ]; then
  if [ -f "$METEOR_PID" ]; then
    kill "$(cat "$METEOR_PID")"
    rm -f "$METEOR_PID"
    # killing the last PID doesn't seem to take down the tree
    killall -q nc meteor_demod meteor_decode
  fi
  if [ -f "$IMAGE" ]; then
    mv -f "$IMAGE" "$DATA/data_${ID}_${DATE}.png"
  fi
fi
