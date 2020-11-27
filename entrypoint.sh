#!/bin/bash
set -e
#avahi-daemon --daemonize --no-drop-root
rigctld -T 127.0.0.1 -m 1 &
exec "$@"
