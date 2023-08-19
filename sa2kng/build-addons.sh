#!/bin/bash
export DOCKER_BUILDKIT=1
TAG="sa2kng-addons"
SATNOGS_IMAGE_TAG="sa2kng"
ARGS="--build-arg SATNOGS_IMAGE_TAG=${SATNOGS_IMAGE_TAG}"

docker build -t librespace/satnogs-client:${TAG} ${ARGS} ../addons
