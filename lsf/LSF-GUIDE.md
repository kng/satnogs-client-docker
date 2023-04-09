# Guide for dockerized satnogs-client

## Intro
This is aimed for those who want to try out the client in docker and thinks it's a bit too complicated.<br>
I will try to explain the basic concepts and how to get up and running.<br>
My preferred distro is Debian 11 (bullseye) and this guide will be tailored for it, but there should only be small differences to others.<br>

## Basic parts of docker, [Official overview](https://docs.docker.com/get-started/overview/)
***Images*** are usually hosted on a registry, for example hub.docker.com, from where you can pull them to your system.
They are the complete software bundled to run an application, in this case a debian image and a lot of packages installed that is required for satnogs-client.<br>
***Container*** is the running instance of an image and is basically an isolated environment where you run the app.
They are always start fresh from the image and can be modified, but it's non-persistent so after a stop any changes are lost.<br>
***Volumes*** is either a persistent storage for containers or bind-mounted to your host for configuration or storage.

***Compose*** This is the main difference from the [old guide](../GUIDE.md), where everything is controlled with the [docker-compose](docker-compose.yml).
In this file all the different services (essentially containers) are specified and all it's settings and relationships between them.
The containers exist on a separate network in this configuration, so rigctld runs in its own container and the satnogs-client talks to this over this network.
What this means is that you don't need a bunch of scripts to start/stop/update everything.
It also means that you don't run several services in the same container.
By default, it creates a stack that is named after the directory the compose file is located in.

# Getting satnogs-client up and running
## Host system
You will need to install the libraries and supporting sw/fw for your sdr device, including udev rules and blacklists.<br>
Additional software such as soapysdr is not needed on the host, but can certainly be installed or if you already have a working ansible install etc.<br>
`sudo apt install rtl-sdr`

See the [docker installation](#install-dockerio) at the bottom of this page.

## Configuration

Start with cloning this repo, or downloading the files in [lsf/](/lsf) to a local directory.
````commandline
git clone https://github.com/kng/satnogs-client-docker.git
cd satnogs-client-docker/lsf
````

The file `station.env` contains all the station variables (earlier in /etc/default/satnogs-client), some of the variables that is important to the function of the stack is located in the compose file.
On a fresh install, copy the `station.env-dist` to `station.env` and edit it.
```commandline
cp station.env-dist station.env
nano station.env
```
Make sure to populate all the lines that are not commented out as these are the important ones.
Also note that the values should not be escaped with quotes or ticks.

## Bringing the stack up

The `docker-compose` (on some systems it's `docker compose` without the hyphen) is the program controlling the creation, updating, building and termination of the stack.
The basic commands you will use is `docker-compose up -d` and `docker-compose down`.
When you edit the compose file or configuration it will try to figure out what needs to be done to bring the stack in sync of what has changed.
For example editing the SDR gain, it will recreate and restart the client but not rigctld.

Starting the stack (and updating after changed config):
```commandline
docker-compose up -d
```

Stopping the stack:
```commandline
docker-compose down
```

Updating the images and bringing the stack up:
```commandline
docker-compose up -d --pull
```

## Monitoring and maintenance

Inside each container, the logs are output to stdout, which makes them visible from outside the container in the logs.
Starting to monitor the running stack:
```commandline
docker-compose logs -f
```

# Additional services and addons
In the [maxed](docker-compose.maxed) yml there's some additional services that can be run, for example rotator and auto-scheduler.
These can be copied in to the [docker-compose.yml](docker-compose.yml) to be activated, do note additions in the section `environment:` in the service satnogs_client needs to be added as well.

## Addons
The gr-satellites integration and addons can be activated by changing the `image:` in the service satnogs_client as seen in the commented line below the default image.
Some additional settings is needed to activate its functionality, simply remove the comment (#) in front of the following lines in `station.env`:
```
SATNOGS_PRE_OBSERVATION_SCRIPT=satnogs-pre {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
SATNOGS_POST_OBSERVATION_SCRIPT=satnogs-post {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
UDP_DUMP_HOST=0.0.0.0
```

## Development and building
TODO, building images, choosing own repos etc.

## Multiple stations on one host
TODO, separating the directories by station name, adressning the rtl-sdr by ID.

# Install Docker.io

In Debian bullseye there's already a docker package, so installation is easy:
```
sudo apt install docker.io apparmor
sudo apt -t bullseye-backports install docker-compose
sudo adduser pi docker
```
Make sure to match the username, where pi is used here above.
The reason for using backports is the version of compose in bullseye is 1.25 and lacks cgroup support, the backport is version 1.27

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
