#!/bin/bash
DOCKER_BUILDKIT=1 docker build . --target=builder
DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:test .
# --no-cache

