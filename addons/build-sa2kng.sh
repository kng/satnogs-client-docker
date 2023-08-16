#!/bin/bash

TAG="sa2kng-addons"
SATNOGS_IMAGE_TAG="sa2kng"

docker build -t librespace/satnogs-client:${TAG} --build-arg SATNOGS_IMAGE_TAG=${SATNOGS_IMAGE_TAG} -f Dockerfile.lsf .
