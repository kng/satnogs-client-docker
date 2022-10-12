#!/bin/bash
git clone -b maint-3.8 --depth 1 https://github.com/daniestevez/gr-satellites.git
cp gr-satellites/python/satyaml/* /usr/lib/python3/dist-packages/satellites/satyaml/
rm -rf gr-satellites /tmp/.satnogs/grsat_list.*

