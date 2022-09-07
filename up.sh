#!/bin/bash
echo "creating container: satnogs-client"
docker run --name satnogs-client --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/.env -d knegge/satnogs-client:latest "$@"

