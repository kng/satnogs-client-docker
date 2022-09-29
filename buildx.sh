#!/bin/bash
#TARGETS=linux/amd64
TARGETS=linux/arm64,linux/amd64,linux/arm/v7,linux/i386

# the builder doesn't get built as it lacks --from=builder ? build implicit
docker buildx build --platform=${TARGETS} . --target=builder
docker buildx build --platform=${TARGETS} -t knegge/satnogs-client:test . --push

