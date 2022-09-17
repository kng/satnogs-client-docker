#!/bin/bash
docker pull knegge/satnogs-client:addons
git clone --depth 1 https://github.com/daniestevez/gr-satellites.git
docker build -t knegge/satnogs-client:addons -f Dockerfile.satyaml .
rm -rf gr-satellites

