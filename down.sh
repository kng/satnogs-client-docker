#!/bin/bash
echo "removing containder: satnogs-client"
docker stop satnogs-client
docker rm satnogs-client

