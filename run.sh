#!/bin/bash
docker run --name satnogs-node --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/var/lib/satnogs/.env -it satnogs-client:latest
