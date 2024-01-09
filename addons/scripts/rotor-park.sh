#!/bin/bash
if [[ ! "${ROT_PARK^^}" =~ (TRUE|YES|1) ]]; then exit; fi
# exit if pipeline fails or unset variables
set -eu
ROTCTL=${SATNOGS_ROT_PORT/:/ }
echo "Parking rotor: $ROTCTL"
echo "P 180 90" | nc -w 1 $ROTCTL
