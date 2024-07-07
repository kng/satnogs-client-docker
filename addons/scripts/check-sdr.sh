#!/bin/bash
cd || exit
echo "Checking SDR..."
if ! SoapySDRUtil --probe="$SATNOGS_SOAPY_RX_DEVICE" >/dev/null 2>&1; then
  echo "SDR Error, restarting."
  sleep 5
  exit 1
fi
echo "SDR OK."
exec "$@"