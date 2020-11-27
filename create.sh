#!/bin/bash
echo "creating docker: satnogs-node"
docker run --name satnogs-node --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/.env -it satnogs-client:latest "$@"
