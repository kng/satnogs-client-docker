#!/bin/bash

TAG="riscv64"
export DOCKER_BUILDKIT=1
ARGS="--build-arg BASE_IMAGE=riscv64/ubuntu:focal"
# --progress=plain

if [ "$1" == "sbuild" ]; then
    # build only the builder, you can run it and test things
    docker build -t knegge/satnogs-client:builder . --target builder ${ARGS}
    echo "Starting shell in builder container... "
    docker run --rm -it knegge/satnogs-client:builder
else
    # build and append result to base image
    docker build -t knegge/satnogs-client:builder . --target builder ${ARGS} &&\
    docker build -t knegge/satnogs-client:${TAG} . ${ARGS}
fi

