# satnogs-client-docker
Run satnogs-client inside one or more docker containers.<br>
Support for regular USB devices. Some (pluto f.ex) that require dbus/avahi will not work unless mapping up these from the host and running as root.

## Building and running
````
git clone --depth=1 https://github.com/kng/satnogs-client-docker.git
cd satnogs-client-docker
docker build -t satnogs-client:latest .
edit satnogs-config
docker run --name satnogs-node --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/.env -it satnogs-client:latest
````

## Comments
The default is running via entrypoint.sh and it is launching rigctld first
