#!/bin/bash
# exit if pipeline fails or unset variables
set -eu
# default values
: "${BANDSCAN_FREQ?Needs to be defined.}"
: "${BANDSCAN_SAMPLERATE:=$SATNOGS_RX_SAMP_RATE}"
: "${BANDSCAN_DIR:=/srv/bandscan}"
: "${SATNOGS_PPM_ERROR:=0}"
: "${BANDSCAN_PID:=/tmp/.satnogs/bandscan.pid}"
: "${BANDSCAN_BIN:=rx_sdr}"
: "${BANDSCAN_OUTPUT_FORMAT:=CF32}"
: "${BANDSCAN_INPUT_FORMAT:=float}"
: "${SATNOGS_RF_GAIN:=0}"
: "${SATNOGS_OTHER_SETTINGS:=0}"

# if unset, try calculating channels
if [ -n "${BANDSCAN_CHANNELS:-}" ]; then
  CHANNELS="$BANDSCAN_CHANNELS"
elif [ "${BANDSCAN_FREQ%.*}" -lt 300000000 ]; then
  CHANNELS="20" # VHF
elif [ "${BANDSCAN_FREQ%.*}" -lt 500000000 ]; then
  CHANNELS="50" # UHF
else
  CHANNELS="100" # S-BAND
fi

if [ "${1^^}" == "START" ] && [ "${BANDSCAN_ENABLE^^}" == "YES" ]; then
    echo "Starting bandscan at $BANDSCAN_FREQ"
    DAY=$(date -Idate)
    SAVEDIR="$BANDSCAN_DIR/$BANDSCAN_FREQ/$DAY"
    mkdir -p "$SAVEDIR" "$(dirname "$BANDSCAN_PID")"
    INDEX=$(find "$SAVEDIR" -mindepth 1 -maxdepth 1 -type f | wc -l)
    $BANDSCAN_BIN -d "$SATNOGS_SOAPY_RX_DEVICE" \
                  -a "$SATNOGS_ANTENNA" \
                  -p "$SATNOGS_PPM_ERROR" \
                  -g "$SATNOGS_RF_GAIN" \
                  -t "$SATNOGS_OTHER_SETTINGS" \
                  -s "$BANDSCAN_SAMPLERATE" \
                  -f "$BANDSCAN_FREQ" \
                  -F "$BANDSCAN_OUTPUT_FORMAT" - \
    | rffft -q \
            -f "$BANDSCAN_FREQ" \
            -s "$BANDSCAN_SAMPLERATE" \
            -F "$BANDSCAN_INPUT_FORMAT" \
            -c "$CHANNELS" \
            -t 1 \
            -p "$SAVEDIR" \
            -o "$DAY" \
            -S "$INDEX" &
    echo $! > "$BANDSCAN_PID"
fi

if [ "${1^^}" == "STOP" ]; then
   if [ -f "$BANDSCAN_PID" ]; then
       echo "Stopping bandscan"
       kill "$(cat "$BANDSCAN_PID")"
       rm -f "$BANDSCAN_PID"
   fi
fi
