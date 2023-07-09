# SA2KNG's satnogs-client addons

## Info

This is a collection of scripts and software builds that can be added to the official docker images.

There is the [legacy version](Dockerfile) that extends my initial images, and there's the [LSF version](Dockerfile.lsf).<br>
These build a bunch of additional software on top of the image, as well as include some useful scripts.

## [satnogs-pre](satnogs-pre) and [satnogs-post](satnogs-post)
This is the glue for everything regarding the observations, they are executed before and after the actual observation. In these you can launch things that can help with automated processing, demodulators and more.

## [iq_dump_rename](iq_dump_rename.sh)
This script helps rename the IQ_DUMP files between the observations, else they're overwritten by the next obs.
Required settings in `station.env` is:
```
ENABLE_IQ_DUMP=Yes
IQ_DUMP_RENAME=Yes
IQ_DUMP_FILENAME=/srv/iq
```
To make use of it you should bind-mount a directory, so it is stored on the host instead of in the image or volume.
Add this to docker-compose.yml in the satnogs_client service, under `volumes:`:
```yaml
    volumes:
      - type: 'bind'
        source: './srv'
        target: '/srv'
```
Before bringing the stack up, the source dir needs to exist, create with `mkdir -p srv`

## [liveupdate-satyaml](liveupdate-satyaml.sh)
This script fetches the latest SatYAML from the main repo. This requires the image to be mounted with read-write, see [docker-compose.yml](../lsf/docker-compose.yml) in the service satnogs_client, comment out the line `#read_only: true`.
It can be auto-executed when the stack is brought up, by adding it in the `command:` key under the satnogs_client service:
```yaml
    command: liveupdate-satyaml.sh satnogs-client
```
It will execute the script, then execute the arguments after it, in this case the client itself.

## [test-flowgraph](test-flowgraph.sh)
This will test the sdr settings by launching a flowgraph and record waterfall and audio, it can be used to quickly verify that the settings in `station.env` is correct.

## [bandscan](bandscan.sh)
A bandscan script that can run in between observations to monitor a frequency and log the data to be later used in the [strf tools](https://github.com/cbassa/strf) 

## [direwolf](direwolf.sh)
Run [direwolf](https://github.com/wb2osz/direwolf) and demodulate APRS in between observations.

## [uhd_images_downloader](uhd_images_downloader.py)
Downloads USRP images from Ettus Research, this is now included in the base image of [docker-gnuradio](https://gitlab.com/librespacefoundation/docker-gnuradio)

## [wf2png](wf2png.py)
This converts a waterfall .dat file to .png

## Repositories built

beesat-sdr for mobitex support https://github.com/daniestevez/beesat-sdr <br>
SSDV with support for DSLWP and JY1SAT modes https://github.com/daniestevez/ssdv <br>
satnogs_gr-satellites https://github.com/kng/satnogs_gr-satellites <br>
mirisdr https://github.com/ericek111/libmirisdr-5 <br>
soapymiri https://github.com/ericek111/SoapyMiri <br>
aptdec https://github.com/Xerbo/aptdec <br>
satellite orbit prediction for tle https://github.com/la1k/libpredict <br>
kalibrate for rtl_sdr https://github.com/steve-m/kalibrate-rtl <br>
rx_fm rx_power rx_sdr https://github.com/rxseger/rx_tools <br>
rffft from strf https://github.com/cbassa/strf <br>
