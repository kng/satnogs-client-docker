# Guide for dockerized satnogs-client

## Intro
This is aimed for those who want to try out the client in docker and thinks it's a bit too complicated.<br>
I will try to explain the basic concepts and how to get up and running.<br>
My preferred distro is Debian 11 (bullseye) and this guide will be tailored for it, but there should only be small differences to others.<br>
You do not need to clone this repo to run the image.

## Basic parts of docker, [Official overview](https://docs.docker.com/get-started/overview/)
***Images*** are usually hosted on a registry, for example hub.docker.com, from where you can pull them to your system.
They are the complete software bundled to run an application, in this case a debian image and a lot of packages installed that is required for satnogs-client.<br>
***Container*** is the running instance of an image and is basically a isolated environment where you run the app.
They are always start fresh from the image and can be modified, but it's non-persistent so after a stop any changes are lost.<br>
***Volumes*** is either a persistent storage for containers or bind-mounted to your host for configuration or storage.

# Getting satnogs-client up and running
## Host system
You will need to install the libraries and supporting sw/fw for your sdr device, including udev rules and blacklists.<br>
Additional software such as soapysdr is not needed on the host, but can certainly be installed or if you already have a working ansible install etc.<br>
`sudo apt install rtl-sdr`

See the [docker installation](#install-dockerio) at the bottom of this page.

## Scripts
I recommend creating a few scripts that can be run to make the management easier.

client-up.sh
```
#!/bin/bash
docker run \
    --name satnogs-client \
    --device=/dev/bus/usb/ \
    --tmpfs /tmp \
    -v ~/satnogs-config:/.env \
    -d knegge/satnogs-client:latest
```

client-down.sh
```
#!/bin/bash
docker stop satnogs-client
docker container rm satnogs-client
```

client-update.sh
```
#!/bin/bash
docker pull knegge/satnogs-client:latest
./client-down.sh
./client-up.sh
```

Make the script executable: `chmod 0755 client-up.sh client-down.sh client-update.sh`

## Client config
If you already have a working config for the station, I recommend copying it. You can also change the scripts to use the system location of the config.<br>
Choose one of the following:
Copy the config to the home directory `cp /etc/default/satnogs-client ~/satnogs-config`<br>
OR<br>
Change the config line in client-up.sh to `-v /etc/default/satnogs-client:/.env \`<br>
Docker will try to create a directory named after the bind-mount if the file doesn't exist, in this case you need to remove the directory.

Template for ~/satnogs-config , edit for your id/token etc.
```
SATNOGS_API_TOKEN=""
SATNOGS_STATION_ID=""
SATNOGS_STATION_LAT=""
SATNOGS_STATION_LON=""
SATNOGS_STATION_ELEV=""
SATNOGS_SOAPY_RX_DEVICE="driver=rtlsdr"
SATNOGS_RX_SAMP_RATE="1.024e6"
SATNOGS_PPM_ERROR="0"
SATNOGS_RF_GAIN="20.7"
SATNOGS_ANTENNA="RX"
SATNOGS_LOG_LEVEL="INFO"
```

## Explanation of the scrips

These are made for a single client, but can easily be modified for running several different clients on one host.<br>
The actual client is started as detached, so you will not see it's output when launched.<br>
First start the container with `./client-up.sh`, first time it will pull and extract the image.<br>
To see what it's doing you can run the log viewer `docker logs satnogs-client -f -t -n 50`, it will show the last 50 rows, timestamped, and follow.
Starting and stopping a container can be done with `docker start satnogs-client` and `docker stop satnogs-client`.<br>

The client-up.sh script details:<br>
`docker run` is the command to create a instance of an image.<br>
`--name satnogs-client` giving it a name.<br>
`--device=/dev/bus/usb/` mapping usb devices into the container, required for rtl-sdr but not plutosdr.<br>
`--tmpfs /tmp` creating a tmpfs of /tmp as satnogs-client stores it's running data here.<br>
`-v ~/satnogs-config:/.env` bind-mounting the configuration file to .env inside the container, which is read by the client.<br>
`-d knegge/satnogs-client:latest` this specifies the image to use, and detach mode. You can replace `-d` with `-it` to run it in foreground.<br>

## Inside the container
When the container starts, it executes [entrypoint.sh](entrypoint.sh) which contains:
```
#!/bin/bash
set -e
rigctld -T 127.0.0.1 -m 1 &
source bin/activate
exec "$@"
```

This starts `rigctld` which is used for the doppler coreection.<br>
Then activates the `virtualenv` located in the satnogs user homedir. It contains all the python requirements.<br>
Last it executes the argument given, in this case `satnogs-client`.<br>
If you're using portainer you can look in the container list if it is running, or use `docker ps -a`.


## [Tags](https://hub.docker.com/r/knegge/satnogs-client/tags)
You may have noticed the `:latest` when referring to the image, this is a tag that points to the latest image.<br>
There can be several images with tags differentiating them, as well as imgages having several tags.<br>
Today there's at least one additional image developed, it contains a set of popular addons and uses the `:latest` image plus a bunch of compiled software.<br>
If you want to use this, replace the `:latest` with `:addons` in the scripts. It will pull this image automatically, and you can swap between them at any time.<br>
Stopping a container does not change the tag, you need to remove and recreate it as is done with the -up and -down scripts.<br>


## Addons
[gr-satellites](https://github.com/daniestevez/gr-satellites) is a popular demod and decoder and there's a integration into satnogs-client, this has been added to the :addons image and to activate it you will need to add a few rows to the config:
```
SATNOGS_PRE_OBSERVATION_SCRIPT="satnogs-pre {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}"
SATNOGS_POST_OBSERVATION_SCRIPT="satnogs-post {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}"
UDP_DUMP_HOST="0.0.0.0"
```
And change the tag in the client-up.sh to: `-d knegge/satnogs-client:addons`.<br>
Then run `./client-down.sh && ./client-up.sh` 

The pre-/post observation script launches [grsat-wrapper.sh](https://github.com/kng/satnogs_gr-satellites/blob/main/grsat-wrapper.sh) and this is the glue between gr-satellites and satnogs-client.<br>
Make sure to remove or comment out these 3 lines if you're running the :latest tag instead of :addons.<br>

## Test SDR
The :addons also has a useful script to test your sdr and config, to launch it you can use this script (remember to set the config path):
```
#!/bin/bash
docker run \
    --device=/dev/bus/usb/ \
    --tmpfs /tmp \
    -v ~/satnogs-config:/.env \
    --rm -it knegge/satnogs-client:addons test-flowgraph.sh
```
Let it run for ~30s and then exit with Ctrl-C.


# Install Docker.io

In Debian bullseye there's already a docker package, so installation is easy:
```
sudo apt install docker.io
sudo adduser pi docker
```

Re-login for the group premission to take effect.

## Recommended install: [Portainer](https://docs.portainer.io/start/install/server/docker/linux)

```
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```
Then browse to https://yourDocker:9443 and follow the instruction, use local socket in the "Get started" section.


# For reference: Install Docker Engine (docker.com)

Refer to [docker installation](https://docs.docker.com/engine/install/debian/) on how to get the latest installed on your system.<br>
Short version, ymmv: Base image: Rasperry Pi OS 64bit or 32bit Lite (bullseye):
```
# already installed: ca-certificates curl lsb-release
# optional: tmux uidmap
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release git

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# add user to docker group, avoid needing sudo, re-login to apply
sudo adduser pi docker
```
