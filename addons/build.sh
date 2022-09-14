#!/bin/bash

#DEV=1

if [ ! -z ${DEV} ]; then
    # build only the builder, you can run it and test things
    docker build -t knegge/satnogs-client:builder . --target builder
    echo "Starting container... "
    docker run --rm -it knegge/satnogs-client:builder
else
    # build and append result to base image
    docker build -t knegge/satnogs-client:addons .
fi

