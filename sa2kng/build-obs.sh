#!/bin/bash
TAG="obs"
REPO_ROOT="knegge"
IMAGE_TAG="lsf-addons"

ARGS="  --build-arg IMAGE_TAG=${IMAGE_TAG}"
ARGS+=" --build-arg REPO_ROOT=${REPO_ROOT}"
ARGS+=" --build-arg OBS_REPO=https://download.opensuse.org/repositories/home:/knegge:/branches:/home:/librespace:/satnogs-unstable/Debian_11/"

docker build \
    -t ${REPO_ROOT}/satnogs-client:${TAG} \
    -f Dockerfile.obs \
    ${ARGS} \
    . "$@"
