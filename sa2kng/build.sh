#!/bin/bash
export DOCKER_BUILDKIT=1
TAG="sa2kng"
REPO_ROOT="knegge"
GNURADIO_IMAGE_TAG="satnogs-unstable"

ARGS="  --build-arg GNURADIO_IMAGE_TAG=${GNURADIO_IMAGE_TAG}"
ARGS+=" --build-arg GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git"
ARGS+=" --build-arg GRSATNOGS_BRANCH=${TAG}"
ARGS+=" --build-arg GRSATNOGS_VER=2.3.4.0+2+${TAG}"
ARGS+=" --build-arg GRSOAPY_URL=https://gitlab.com/knegge/gr-soapy.git"
ARGS+=" --build-arg GRSOAPY_BRANCH=${TAG}"
ARGS+=" --build-arg GRSOAPY_VER=2.1.3.1+2+${TAG}"
ARGS+=" --build-arg FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git"
ARGS+=" --build-arg FLOWGRAPHS_BRANCH=${TAG}"
ARGS+=" --build-arg FLOWGRAPHS_VER=1.5+2+${TAG}"
ARGS+=" --build-arg CLIENT_URL=https://gitlab.com/knegge/satnogs-client.git"
ARGS+=" --build-arg CLIENT_BRANCH=${TAG}"
#ARGS+=" --build-arg RTLSDR_URL=https://github.com/osmocom/rtl-sdr.git"
#ARGS+=" --build-arg RTLSDR_BRANCH=master"
#ARGS+=" --build-arg RTLSDR_VER=0.6.0+2+${TAG}"
#ARGS+=" --build-arg UHD_URL=http://archive.ubuntu.com/ubuntu/pool/universe/u/uhd/uhd_4.1.0.5-3.dsc"
#ARGS+=" --build-arg OBS_REPO=https://download.opensuse.org/repositories/home:/knegge:/branches:/home:/librespace:/satnogs-unstable/Debian_11/"

docker build \
    -t ${REPO_ROOT}/satnogs-client:${TAG} \
    ${ARGS} \
    . "$@"
