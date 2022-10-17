#!/bin/bash

if [ "$1" == "dev" ]; then
    # build only the builder, you can run it and test things
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:builder . --target builder
    echo "Starting container... "
    docker run --rm -it knegge/satnogs-client:builder
else
    # build and append result to base image
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:builder . --target builder &&\
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:test .
fi

