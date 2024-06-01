#!/bin/bash
cd || exit
sdrplay_apiService &
exec "$@"