#!/bin/bash

TAG="dev"
export DOCKER_BUILDKIT=1
#ARGS="--build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git \
#      --build-arg GRSATNOGS_BRANCH=master \
#      --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git \
#      --build-arg FLOWGRAPHS_BRANCH=ssb \
#      --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git \
#      --build-arg CLIENT_BRANCH=ssb"

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

