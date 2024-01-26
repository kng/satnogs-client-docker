#!/bin/bash
export DOCKER_BUILDKIT=1
if [ "${1^^}" == "DEV" ]; then
    TAG="lsf-dev-addons"
    SATNOGS_IMAGE_TAG="master-unstable"
else
    TAG="lsf-addons"
    SATNOGS_IMAGE_TAG="master"
fi
REPO_ROOT="knegge"

ARGS="  --build-arg SATNOGS_IMAGE_TAG=${SATNOGS_IMAGE_TAG}"
#ARGS+=" --build-arg CMAKE_BUILD_PARALLEL_LEVEL=8"

docker build \
    -t ${REPO_ROOT}/satnogs-client:${TAG} \
    ${ARGS} \
    . "$@"
