#!/bin/bash
#SATNOGS_RIG_IP=rigctld
CLIENT=satnogs-client
RIGIP=$(getent hosts "$SATNOGS_RIG_IP" | awk '{ print $1 }')
FLOWGRAPHS=(/usr/bin/satnogs_*.py)
OUTPATH=~/.local/bin

if [ -z "$RIGIP" ]; then
    echo "Warning: unable to resolve SATNOGS_RIG_IP"
    exec $CLIENT
fi

if grep -q "tcp_rigctl_msg_source(\"127.0.0.1" "$FLOWGRAPHS"; then
    echo "Updating flowgraphs..."
    mkdir -p "$OUTPATH"
    for FG in "${FLOWGRAPHS[@]}"; do
        F=${FG##*/}
        echo "$F"
        sed "s/tcp_rigctl_msg_source(\"127.0.0.1\"/tcp_rigctl_msg_source(\"$RIGIP\"/" "$FG" > "$OUTPATH/$F"
        chmod 0755 "$OUTPATH/$F"
    done
    export PATH=$OUTPATH:$PATH
fi
echo "Starting $CLIENT"
exec $CLIENT

