#!/bin/bash
export DOCKER_BUILDKIT=1
TAG="sa2kng"
ARGS="--build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git \
      --build-arg GRSATNOGS_BRANCH=master \
      --build-arg GRSOAPY_URL=https://gitlab.com/knegge/gr-soapy.git \
      --build-arg GRSOAPY_BRANCH=master \
      --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git \
      --build-arg FLOWGRAPHS_BRANCH=sa2kng \
      --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git \
      --build-arg CLIENT_BRANCH=sa2kng"

docker build -t librespace/satnogs-client:${TAG} ${ARGS} -f Dockerfile.rtlsdr .
