#!/bin/bash
# suggested variables to set in config
# ENABLE_IQ_DUMP="yes"
# IQ_DUMP_FILENAME="/srv/iq"
# IQ_DUMP_RENAME="yes"
# IQ_DUMP_COMPRESS="yes"

if [ "${ENABLE_IQ_DUMP^^}" == "YES" ] && [ "${IQ_DUMP_RENAME^^}" == "YES" ]; then
    SAMP=$(find_samp_rate.py "$5" "$6")
    NAME="${IQ_DUMP_FILENAME}_${1}_${SAMP}.raw"
    mv "${IQ_DUMP_FILENAME}" "${NAME}"
    if [ "${IQ_DUMP_COMPRESS^^}" == "YES" ]; then
        zstd --no-progress --rm -f "${NAME}"
    fi
fi
