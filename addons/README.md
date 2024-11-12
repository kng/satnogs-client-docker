# SA2KNG's satnogs-client addons

## Info

This is a collection of scripts and software builds that can be added to the official docker images.

These build a bunch of additional software on top of the image, as well as include some useful scripts.

## [satnogs-pre](scripts/satnogs-pre) and [satnogs-post](scripts/satnogs-post)
This is the glue for everything regarding the observations, they are executed before and after the actual observation. In these you can launch things that can help with automated processing, demodulators and more.<br>
By default, I recommend these two as they have been used for a long time and many other stations use them:
```
SATNOGS_PRE_OBSERVATION_SCRIPT=satnogs-pre {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
SATNOGS_POST_OBSERVATION_SCRIPT=satnogs-post {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
```

## [grsat.py](scripts/grsat.py)
This is the [gr-satellites](https://github.com/daniestevez/gr-satellites) integration into the client.<br>
It needs the UDP output to be enabled in the flowgraphs and the above pre-/post- scripts.
```
UDP_DUMP_HOST=0.0.0.0
```

The main idea is to get the doppler corrected IQ stream from the flowgraph into a running gr_satellites in UDP raw mode.<br>
Pre-obs script launches gr-satellites in the background and it’s output is directed to a log file and a KISS file.<br>
Post-obs stops the gr_satellites and looks for any KISS data, parses and creates the necessary files for upload via the satnogs-client.

## [imagedecode.py](scripts/imagedecode.py)
TODO: document the image decoder

## [gpio.py](scripts/gpio.py)
TODO: document IO control

## [SatDump](scripts/satdump.sh)
TODO: finish the implementation and document

## [iq_dump_rename](scripts/iq_dump_rename.sh)
This script helps rename the IQ_DUMP files between the observations, else they're overwritten by the next obs.
Required settings in `station.env` is:
```
ENABLE_IQ_DUMP=true
IQ_DUMP_RENAME=true
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

## [liveupdate-satyaml](scripts/liveupdate-satyaml.sh)
This script fetches the latest SatYAML from the main repo. This requires the image to be mounted with read-write, see [docker-compose.yml](../lsf/docker-compose.yml) in the service satnogs_client, comment out the line `#read_only: true`.
It can be auto-executed when the stack is brought up, by adding it in the `command:` key under the satnogs_client service:
```yaml
    command: liveupdate-satyaml.sh satnogs-client
```
It will execute the script, then execute the arguments after it, in this case the client itself.

## [test-flowgraph](scripts/test-flowgraph.sh)
This will test the sdr settings by launching a flowgraph and record waterfall and audio, it can be used to quickly verify that the settings in `station.env` is correct.

## [bandscan](scripts/bandscan.sh)
A bandscan script that can run in between observations to monitor a frequency and log the data to be later used in the [strf tools](https://github.com/cbassa/strf)<br>
The `rx_sdr` will use the device, antenna, gain etc from the satnogs settings.<br>
Configuration in `station.env`, the only required is enable, all the others have defaults:
```shell
BANDSCAN_ENABLE=true
BANDSCAN_FREQ=435000000 # default 401M
BANDSCAN_SAMPLERATE=2e6 # override the default from SATNOGS_RX_SAMP_RATE
BANDSCAN_DIR=/srv/bandscan # make sure to bind-mount a path from the host
```

## [direwolf](scripts/direwolf.sh)
Run [direwolf](https://github.com/wb2osz/direwolf) and demodulate APRS in between observations.<br>
The `rx_sdr` will use the device, antenna, gain etc from the satnogs settings.<br>
Configuration in `station.env`, the only required is  enable, all the others have defaults:
```
DIREWOLF_ENABLE=true
DIREWOLF_FREQ=144800000 # EU 144.8M, modify for NA 144.39M
DIREWOLF_CONF=/etc/direwolf.conf # change to /var/lib/satnogs-client/direwolf.conf for custom config
```
The default config only displays decoded APRS. If you want to run it as a IGate you will need to build a custom configuration and save it in the home volume.<br>
Use a text editor to make the config, then copy the contents and paste it in the following procedure.<br>
Launch a shell in the running client container `docker compose exec satnogs_client bash`.<br>
Terminate the cat command with Ctrl-D after pasting in the contents:
```shell
cat > ~/direwolf.conf
ADEVICE stdin null
ADEVICE - null
MYCALL xx-10
IGSERVER euro.aprs2.net
IGLOGIN xx-10 12345
IBEACON DELAY=1 EVERY=30 VIA=WIDE1-1 SENDTO=IG
PBEACON DELAY=1 EVERY=30 OVERLAY=S SYMBOL="digi" LAT=xx^yy.zzN LONG=xxx^yy.zzE HEIGHT=20 POWER=0 GAIN=4 COMMENT="SatNOGS #xx" VIA=WIDE1-1,WIDE2-1 SENDTO=IG
```
Make sure to change all xx/yy/zz to values for your station.<br>
Normally the direwolf script is started after a observation, so it doesn't start automatically when the container is started.
You can launch it manually in a docker shell with `direwolf.sh start`.

## [meteor](scripts/meteor.sh)
Demodulate Meteor-M2 images from the UDP stream.
Based on [meteor_demod](https://github.com/dbdexter-dev/meteor_demod) and [meteor_decode](https://github.com/dbdexter-dev/meteor_decode)<br>
Configuration in `station.env`:
```
UDP_DUMP_HOST=0.0.0.0 # required, enable UDP output from flowgraphs
METEOR_NORAD=57166 # optional, space separated list of ID's to activate demodulation
```

## Miri SDR
[libmirisdr-5](https://github.com/ericek111/libmirisdr-5) and [SoapyMiri](https://github.com/ericek111/SoapyMiri)

## SDRplay
The [api](https://www.sdrplay.com/api/) is installed and [SoapySDRPlay3](https://github.com/pothosware/SoapySDRPlay3).<br>
To run it you need to change the [docker-compose.yml](../lsf/docker-compose.yml) command in the client to `command: 'sdrplay.sh satnogs-client'`<br>
If the api is run for the first time, the USB device will reconnect and that makes the container loose access to it.<br>
It looks like this in dmesg:
```
usb 2-14: USB disconnect, device number 16
usb 2-14: new high-speed USB device number 18 using xhci_hcd
```

To deal with this automatically, use the `check-sdr.sh` script that probes for the SDR and restarts if needed.
Change the command to `command: 'sdrplay.sh check-sdr.sh satnogs-client' to use this functionality.

To deal with it manually, simply probe first, then restart the container/stack, and it will be able to access the device.<br>
To see if it is working, launch a shell inside the client container `docker compose exec satnogs_client bash` and run:
`SoapySDRUtil --probe="driver=sdrplay"`

## [wf2png](scripts/wf2png.py)
This converts a waterfall .dat file to .png

## [satnogs-monitor](https://github.com/wose/satnogs-monitor/)
Rust application for monitoring your station live.<br>
Refer to the [example config](https://github.com/wose/satnogs-monitor/blob/master/monitor/examples/config.toml).<br>
Minimal config that only sets the required station ID, change XXXX:
```
[[stations]]
satnogs_id = XXXX
local = true
```
Open it up locally in a text editor, edit, copy the contents and paste into this:<br>
`docker-compose exec satnogs_client bash -c "mkdir -p ~/.config/satnogs-monitor/ && cat > ~/.config/satnogs-monitor/config.toml"`<br>
After pasting the contents, press Ctrl-D<br>
Launching it with `docker-compose exec satnogs_client satnogs-monitor`

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
Meteor-M2 series demodulator from https://github.com/dbdexter-dev/meteor_demod <br>
Meteor-M series LRPT decoder https://github.com/dbdexter-dev/meteor_decode <br>
SatNOGS Monitor https://github.com/wose/satnogs-monitor <br>
URESAT-1 decoder https://github.com/AMSAT-EA/URESAT-1-decoder <br>
