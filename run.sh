#!/bin/bash
echo "starting temporary docker"
docker run --rm --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/.env -it satnogs-client:latest "$@"
