#!/bin/bash
# suggested variables to set in config
# ENABLE_IQ_DUMP="yes"
# IQ_DUMP_FILENAME="/srv/iq"
# IQ_DUMP_RENAME="yes"

if [ "${ENABLE_IQ_DUMP^^}" == "YES" ] && [ "${IQ_DUMP_RENAME^^}" == "YES" ]; then
    SAMP=$(find_samp_rate.py "$5" "$6")
    mv "${IQ_DUMP_FILENAME}" "${IQ_DUMP_FILENAME}_${1}_${SAMP}.raw"
fi
