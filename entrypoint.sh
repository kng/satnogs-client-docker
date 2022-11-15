#!/bin/bash
set -e
if [ -f "/.env" ]; then
    source /.env
fi

if [ ! -f ~/.volk/volk_config ]; then
    echo "Volk config not found, generating. This will take a few minutes."
    volk_profile
fi

rigctld -T 127.0.0.1 -m 1 &
source bin/activate
if [ -n "${DOCKER_PRE_SCRIPT}" ]; then
    $DOCKER_PRE_SCRIPT
fi
exec "$@"
