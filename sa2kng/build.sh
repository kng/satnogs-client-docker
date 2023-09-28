#!/bin/bash
export DOCKER_BUILDKIT=1
TAG="sa2kng"
REPO_ROOT="knegge"
GNURADIO_IMAGE_TAG="satnogs-unstable"
ARGS="
    --build-arg GNURADIO_IMAGE_TAG=${GNURADIO_IMAGE_TAG} \
    --build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git \
    --build-arg GRSATNOGS_BRANCH=${TAG} \
    --build-arg GRSATNOGS_VER=2.3.4.0+2+${TAG} \
    --build-arg GRSOAPY_URL=https://gitlab.com/knegge/gr-soapy.git \
    --build-arg GRSOAPY_BRANCH=${TAG} \
    --build-arg GRSOAPY_VER=2.1.3.1+2+${TAG} \
    --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git \
    --build-arg FLOWGRAPHS_BRANCH=${TAG} \
    --build-arg FLOWGRAPHS_VER=1.5+2+${TAG} \
    --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git \
    --build-arg CLIENT_BRANCH=${TAG} \
    --build-arg RTLSDR_URL=https://github.com/osmocom/rtl-sdr.git \
    --build-arg RTLSDR_BRANCH=master \
    --build-arg RTLSDR_VER=0.6.0+2+${TAG} \
"

docker build \
    -t ${REPO_ROOT}/satnogs-client:${TAG} \
    ${ARGS} \
    .
