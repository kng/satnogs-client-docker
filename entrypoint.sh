#!/bin/bash
set -e
rigctld -T 127.0.0.1 -m 1 &
source bin/activate
exec "$@"
