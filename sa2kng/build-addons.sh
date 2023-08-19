#!/bin/bash

TAG="sa2kng-addons"
SATNOGS_IMAGE_TAG="sa2kng"
cd ../addons || exit 1
docker build -t librespace/satnogs-client:${TAG} --build-arg SATNOGS_IMAGE_TAG=${SATNOGS_IMAGE_TAG} .
