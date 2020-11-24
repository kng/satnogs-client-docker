# satnogs-client-docker
Run satnogs-client inside one or more docker containers

## Building and running
````
git clone --depth=1 https://github.com/kng/satnogs-client-docker.git
cd satnogs-client-docker
docker build -t satnogs-client:latest .
edit satnogs-config
docker run --name satnogs-node --device=/dev/bus/usb/ --tmpfs /tmp -v $(pwd)/satnogs-config:/var/lib/satnogs/.env -it satnogs-client:latest
````

## Comments
The default is running via supervisord, but can be run with startup script instead: /usr/local/bin/satnogs-run.sh
