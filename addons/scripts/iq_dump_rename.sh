#!/bin/bash
# suggested variables to set in config
# ENABLE_IQ_DUMP="True"
# IQ_DUMP_FILENAME="/srv/iq"
# IQ_DUMP_RENAME="True"
# IQ_DUMP_COMPRESS="True"

if [[ "${ENABLE_IQ_DUMP^^}" =~ (TRUE|YES|1) ]] && [[ "${IQ_DUMP_RENAME^^}" =~ (TRUE|YES|1) ]]; then
    SAMP=$(find_samp_rate.py "$5" "$6")
    NAME="${IQ_DUMP_FILENAME}_${1}_${SAMP}.raw"
    mv "${IQ_DUMP_FILENAME}" "${NAME}"
    if [[ "${IQ_DUMP_COMPRESS^^}" =~ (TRUE|YES|1) ]]; then
        zstd --no-progress --rm -f "${NAME}"
    fi
fi
