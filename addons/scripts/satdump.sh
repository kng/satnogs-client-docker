#!/bin/bash
if [[ ! "${SATDUMP_ENABLE^^}" =~ (TRUE|YES|1) ]]; then exit; fi
set -eu

# {command} {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
CMD="$1"     # $1 [start|stop]
ID="$2"      # $2 observation ID
FREQ="$3"    # $3 frequency
TLE="$4"     # $4 used tle's
DATE="$5"    # $5 timestamp Y-m-dTH-M-S
BAUD="$6"    # $6 baudrate
SCRIPT="$7"  # $7 script name, satnogs_bpsk.py

PRG="SatDump:"
: "${SATNOGS_APP_PATH:=/tmp/.satnogs}"
: "${SATNOGS_OUTPUT_PATH:=/tmp/.satnogs/data/}"
: "${UDP_DUMP_PORT:=57356}"
: "${SATDUMP_KEEPLOGS:=no}"
BIN=$(command -v satdump)
LOG="SATNOGS_APP_PATH/satdump_$ID.log"
OUT="SATNOGS_APP_PATH/satdump_$ID"
PID="SATNOGS_APP_PATH/satdump_$SATNOGS_STATION_ID.pid"

SATNAME=$(echo "$TLE" | jq .tle0 | sed -e 's/ /_/g' | sed -e 's/[^A-Za-z0-9._-]//g')
NORAD=$(echo "$TLE" | jq .tle2 | awk '{print $2}')

if [ "${CMD^^}" == "START" ]; then
  if [ -z "$UDP_DUMP_HOST" ]; then
	  echo "$PRG WARNING! UDP_DUMP_HOST not set, no data will be sent to the demod"
  fi
  SAMP=$(find_samp_rate.py "$BAUD" "$SCRIPT")
  if [ -z "$SAMP" ]; then
    SAMP=66560
    echo "$PRG WARNING! find_samp_rate.py did not return valid sample rate!"
  fi
  OPT=""
  case "$NORAD" in
    "25338") # NOAA 15
      OPT="live noaa_apt $OUT --source udp_source --port $UDP_DUMP_PORT --satellite_number 15 --samplerate $SAMP"
      ;;
    "28654") # NOAA 18
      OPT="live noaa_apt $OUT --source udp_source --port $UDP_DUMP_PORT --satellite_number 18 --samplerate $SAMP"
      ;;
    "33591") # NOAA 19
      OPT="live noaa_apt $OUT --source udp_source --port $UDP_DUMP_PORT --satellite_number 19 --samplerate $SAMP"
      ;;
  esac

  if [ -n "$OPT" ]; then
    mkdir -p "$OUT"
    echo "$PRG running at $SAMP sps on $SATNAME"
    $BIN $OPT > "$LOG" 2>> "$LOG" &
    echo $! > "$PID"
  fi
fi

if [ "${CMD^^}" == "STOP" ]; then
  if [ -f "$PID" ]; then
    echo "$PRG Stopping observation $ID"
    kill "$(cat "$PID")"
    rm -f "$PID"
  fi

  if [ -s "$OUT" ]; then
    echo "$PRG processing data to network"
    # find images, rename/move to ${SATNOGS_OUTPUT_PATH}/data_<obsid>_YYYY-MM-DDTHH-MM-SS.png
    ls "$OUT"
    if [ ! "${SATDUMP_KEEPLOGS^^}" == "YES" ]; then
      rm -rf "$OUT"
    fi
  fi

  if [ ! -s "$LOG" ] || [ ! "${SATDUMP_KEEPLOGS^^}" == "YES" ]; then
    rm -f "$LOG"
  else
    echo "$PRG Keeping logs, you need to purge them manually."
  fi
fi
