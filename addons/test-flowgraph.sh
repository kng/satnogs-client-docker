#!/bin/bash

if [ -f /.env ]; then
    source /.env
fi

if [ -z "${RX_FREQ}" ]; then
    RX_FREQ="435000000"
fi

if [ -z "${SATNOGS_PPM_ERROR}" ]; then
    SATNOGS_PPM_ERROR="0"
fi

BIN="satnogs_fm.py"
ARGS="--soapy-rx-device=${SATNOGS_SOAPY_RX_DEVICE} --samp-rate-rx=${SATNOGS_RX_SAMP_RATE} --rx-freq=${RX_FREQ} --file-path=test.ogg --waterfall-file-path=test.dat --decoded-data-file-path=test_data --gain=${SATNOGS_RF_GAIN} --antenna=${SATNOGS_ANTENNA} --ppm=${SATNOGS_PPM_ERROR}"

echo "Running rx at ${RX_FREQ}, press Ctrl-C to terminate."
rigctl -m 2 -r 127.0.0.1:4532 F "${RX_FREQ}"
${BIN} ${ARGS}
echo "Generating waterfall..."
wf2png.py test

