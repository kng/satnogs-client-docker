#!/bin/bash
ROTCTL=${SATNOGS_ROT_PORT/:/ }
echo "Parking rotor: $ROTCTL"
echo "P 180 90" | nc -w 1 $ROTCTL
