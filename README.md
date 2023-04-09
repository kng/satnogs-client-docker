# satnogs-client-docker

IMPORTANT: I'm moving to the [Libre Space Foundation](https://hub.docker.com/u/librespace) base images, the standalone build will stay for reference.

The recommended guide for getting started [is here](lsf/LSF-GUIDE.md) for LSF images.

## OLD Installation (see above)
***Please see the [guide](GUIDE.md) on how to get this up and running***.<br>
Cloning and building are not needed if you just want to run it.


Run satnogs-client inside one or more docker containers.<br>
Support for regular USB devices. Some (pluto f.ex) that require dbus/avahi will not work unless mapping up these from the host and running as root.

## Building and running
If you want to build and/or modify it to your needs:
````
git clone --depth=1 https://github.com/kng/satnogs-client-docker.git
cd satnogs-client-docker
docker build -t satnogs-client:latest .
edit satnogs-config
docker run --name satnogs-client --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/.env -it satnogs-client:latest
````

## Comments
The default is running via entrypoint.sh and it is launching rigctld first
