# The SA2KNG collection of branches

## Intro
This is intended to be a collection image of my work that has not yet been merged into upstream.<br>
It is based on the [gnuradio](https://gitlab.com/librespacefoundation/docker-gnuradio) image and critical packages are rebuilt and installed.<br>
The current list of repos is set in [build.sh](build.sh) and consists of gr-satnogs, gr-soapy, satnogs-flowgraphs and satnogs-client.

## Building
To build the image, run: `./build.sh`<br>
To build the addons on top of that, run `./build-addons.sh`<br>
These will build and tag the images `knegge/satnogs-client:sa2kng` and `knegge/satnogs-client:sa2kng-addons` respectively, this can be changed in the build scripts.

To use these, refer to the main [LSF-GUIDE](../lsf/LSF-GUIDE.md). Change the image tag under `satnogs_client:` service in the `docker-compose.yml`.
