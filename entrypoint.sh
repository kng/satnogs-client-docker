#!/bin/bash
set -e
if [ -f "/.env" ]; then
    source /.env
fi
rigctld -T 127.0.0.1 -m 1 &
source bin/activate
if [ -n "${DOCKER_PRE_SCRIPT}" ]; then
    $DOCKER_PRE_SCRIPT
fi
exec "$@"
