#!/bin/bash

if [ "${1^^}" == "DEV" ]; then
    TAG="lsf-dev-addons"
    SATNOGS_IMAGE_TAG="master-unstable"
else
    TAG="lsf-addons"
    SATNOGS_IMAGE_TAG="master"
fi

docker build -t librespace/satnogs-client:${TAG} --build-arg SATNOGS_IMAGE_TAG=${SATNOGS_IMAGE_TAG} .
