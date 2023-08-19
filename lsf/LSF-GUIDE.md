# Guide for LSF satnogs-client with docker compose

## Intro
This is aimed for those who want to try out the client in docker and thinks it's a bit too complicated.<br>
I will try to explain the basic concepts and how to get up and running.<br>
My preferred distro is Debian 11 (bullseye) and this guide will be tailored for it, but there should only be small differences to others.<br>

## Basic description of Docker
[Official overview](https://docs.docker.com/get-started/overview/)

***Images*** are usually hosted on a registry, for example hub.docker.com, from where you can pull them to your system.
They are the complete software bundled to run an application, in this case a debian image and a lot of packages installed that is required for satnogs-client.<br>
***Container*** is the running instance of an image and is basically an isolated environment where you run the app.
They are always start fresh from the image and can be modified, but it's non-persistent so after a stop any changes are lost.<br>
***Volumes*** is either a persistent storage for containers or bind-mounted to your host for configuration or storage.

***Compose*** This is the main difference from the [old guide](../GUIDE.md), where everything is controlled with the [docker-compose](docker-compose.yml).
In this file all the different services (essentially containers) are specified and all it's settings and relationships between them.
The containers exist on a separate network in this configuration, so rigctld runs in its own container and the satnogs-client talks to it over this network.
What this means is that you don't need a bunch of scripts to start/stop/update everything.
It also means that you don't run several services in the same container.
By default, it creates a stack that is named after the directory the compose file is located in.

***Stack*** In this context, is the resulting containers, network, volumes etc. that is created and controlled with compose.

# Getting satnogs-client up and running
## Host system
You will need to install the libraries and supporting sw/fw for your sdr device, including udev rules and blacklists.<br>
Additional software such as soapysdr is not needed on the host, but can certainly be installed or if you already have a working ansible install etc.<br>
Make sure to keep the host clock synchronized, this is absolutely essential and easily solved with ntp.
```shell
sudo apt install rtl-sdr ntp
echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtlsdr.conf
sudo modprobe -r dvb_usb_rtl28xxu
```

See the [docker installation](#install-dockerio) at the bottom of this page.

## Configuration

Start with creating a directory with a name representing the station, this will be shown in several places in the resulting stack.
It is also separates multiple stations running on the same host. 
```shell
mkdir -p station-351
cd station-351
wget https://github.com/kng/satnogs-client-docker/raw/main/lsf/docker-compose.yml
wget -O station.env https://github.com/kng/satnogs-client-docker/raw/main/lsf/station.env-dist
```

The file `station.env` contains all the station variables (earlier in /etc/default/satnogs-client), some of the variables that is important to the function of the stack is located in the compose file.
Use your favourite editor to configure this:
```shell
nano station.env
```
Make sure to populate all the lines that are not commented out as these are the important ones.
Also note that the values should not be escaped with quotes or ticks.

User guide for satnogs-client [configuration](https://docs.satnogs.org/projects/satnogs-client/en/stable/userguide.html#environment-variables).

## Bringing the stack up

The `docker-compose` (on some systems it's `docker compose` without the hyphen) is the program controlling the creation, updating, building and termination of the stack.
The basic commands you will use is `docker-compose up -d` and `docker-compose down`.
When you edit the compose file or configuration it will try to figure out what needs to be done to bring the stack in sync of what has changed.
For example editing the SDR gain, it will recreate and restart the client but not rigctld.

Starting the stack (and updating after changed config):
```shell
docker-compose up -d
```

Stopping the stack:
```shell
docker-compose down
```

Updating the images and bringing the stack up:
```shell
docker-compose pull
docker-compose up -d
```

Over time there will be old images accumulating, these can be removed with `docker image prune -af`

## Monitoring and maintenance

Inside each container, the logs are output to stdout, which makes them visible from outside the container in the logs.
Starting to monitor the running stack:
```shell
docker-compose logs -f
```

If you want to run commands inside the containers, this can be done with the following command:
````shell
docker-compose exec satnogs_client bash
````
The container can be any of the running services, not possible in stopped container thou. Exit with Ctrl-D or typing `exit`.

# Additional services, experimental and addons
In the [maxed](docker-compose.maxed) yml there's some additional services that can be run, for example rotator and auto-scheduler.
These can be copied in to the [docker-compose.yml](docker-compose.yml) to be activated, do note additions in the section `environment:` in the service satnogs_client needs to be added as well.

## Experimental
In the past, the experimental setting switched the station software over to bleeding edge, but the drawback was that you could not go back to stable if there were issues.
This is no longer the case, as these are separated in images and they can easily be switched between as often you like.

Editing the [docker-compose.yml](docker-compose.yml) and going down to the satnogs_client service, the `image:` key specifies the image used.
In this case simply comment out the stable image and uncomment the unstable, or change to any other tag that might be available in the future.
````yaml
  satnogs_client:
    #image: registry.gitlab.com/librespacefoundation/satnogs/satnogs-client/satnogs-client:master  # LSF stable docker image
    image: registry.gitlab.com/librespacefoundation/satnogs/satnogs-client/satnogs-client:master-unstable  # LSF experimental docker image
````
The available tags you can use is listed on [gitlab registry](https://gitlab.com/librespacefoundation/satnogs/satnogs-client/container_registry/3553292) and on [dockerhub](https://hub.docker.com/r/librespace/satnogs-client/tags), two tags are available today: master and master-unstable.
<br>Recreate the container with the usual `docker-compose up -d` 

## Addons
The addons image is documented [here](../addons/README.md), there is a lot more functionality than just the gr-satellites integration.<br>
The gr-satellites integration and addons can be activated by changing the `image:` in the service satnogs_client as seen in the commented lines below the default image.<br>
Two images exist today, `:lsf-addons` which is bases on the stable `:master`, and `:lsf-dev-addons` which is based on experimental `:master-unstable`.<br>
Some additional settings is needed to activate its functionality, simply remove the comment (#) in front of the following lines in `station.env`:
```
SATNOGS_PRE_OBSERVATION_SCRIPT=satnogs-pre {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
SATNOGS_POST_OBSERVATION_SCRIPT=satnogs-post {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}
UDP_DUMP_HOST=0.0.0.0
```

Please note that the -pre/-post scripts need to exist in the image, else observations will fail, so make sure to comment out the above lines if you go back to the default image.

There is a lot more functionality in the addons, please check out the [repo](https://github.com/kng/satnogs-client-docker/tree/main/addons) for the latest information.

## Development and building
TODO, building images, choosing own repos etc.

## Multiple stations on one host
TODO, separating the directories by station name, adressning the rtl-sdr by ID.

# Install Docker.io
If you are using Debian 12 bookworm the installation should be pretty straightforward as the packages are new enough.
```shell
sudo apt install docker.io apparmor docker-compose
sudo adduser $(whoami) docker
```

In Debian 11 bullseye there is a docker package, but compose is too old, so we need to install it from backports:
```shell
sudo apt install docker.io apparmor
sudo apt -t bullseye-backports install docker-compose
sudo adduser $(whoami) docker
```
Re-login for the group permission to take effect.

The reason for using backports is the version of compose in bullseye is 1.25 and lacks cgroup support, the backport is version 1.27
<br>If your dist doesn't have backports, enable with this, and try the installation of docker-compose again:
```shell
echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys  648ACFD622F3D138 0E98404D386FA1D9
sudo apt update
```
If you cannot get a good compose version with your dist, please follow [the official guide](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually).<br>
I made a small script to fetch the latest compose and buildx ([YMMV](https://www.urbandictionary.com/define.php?term=ymmv)) [update-docker-cli.sh](../update-docker-cli.sh):
```shell
wget https://github.com/kng/satnogs-client-docker/raw/main/addons/update-docker-cli.sh
chmod 0755 update-docker-cli.sh
./update-docker-cli.sh
```

## Recommended install: [Portainer](https://docs.portainer.io/start/install/server/docker/linux)

```shell
docker volume create portainer_data
docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
```
Then browse to https://127.0.0.1:9443 (change to the correct host on the network) and follow the instruction, use local socket in the "Get started" section.


# For reference: Install Docker Engine (docker.com)

Refer to [docker installation](https://docs.docker.com/engine/install/debian/) on how to get the latest installed on your system.<br>
Short version, ymmv: Base image: Rasperry Pi OS 64bit or 32bit Lite (bullseye):
```shell
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
sudo adduser $(whoami) docker
```
