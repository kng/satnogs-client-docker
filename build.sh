#!/bin/bash

ARGS="--build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git \
      --build-arg GRSATNOGS_BRANCH=master \
      --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git \
      --build-arg FLOWGRAPHS_BRANCH=ssb \
      --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git \
      --build-arg CLIENT_BRANCH=ssb"

if [ "$1" == "dev" ]; then
    # build only the builder, you can run it and test things
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:builder . --target builder $ARGS
    echo "Starting container... "
    docker run --rm -it knegge/satnogs-client:builder
else
    # build and append result to base image
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:builder . --target builder $ARGS &&\
    DOCKER_BUILDKIT=1 docker build -t knegge/satnogs-client:test .
fi

