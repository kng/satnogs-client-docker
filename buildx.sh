#!/bin/bash
TAG=ssb
TARGETS=linux/arm64,linux/amd64,linux/arm/v7,linux/i386
ARGS="--build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git \
      --build-arg GRSATNOGS_BRANCH=master \
      --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git \
      --build-arg FLOWGRAPHS_BRANCH=ssb \
      --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git \
      --build-arg CLIENT_BRANCH=ssb"

# the builder doesn't get built as it lacks --from=builder ? build implicit
#docker buildx build --platform=${TARGETS} . --target=builder ${ARGS}
docker buildx build --platform=${TARGETS} -t knegge/satnogs-client:${TAG} . ${ARGS} --push

