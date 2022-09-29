# syntax = docker/dockerfile:1.2
FROM debian:bullseye as builder

RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends unzip git python3-pip libhdf5-103 python3-virtualenv virtualenv build-essential gfortran pkg-config libhdf5-dev python3-dev python3-libhamlib2 python3-gps

WORKDIR /env
RUN virtualenv -p python3 --no-seed .
RUN . bin/activate && pip3 install --upgrade pip setuptools wheel ujson --prefer-binary --extra-index-url https://www.piwheels.org/simple
RUN --mount=type=cache,id=wheels,target=/wheels . bin/activate && pip3 wheel satnogs-client~=1.8 -w /wheels --prefer-binary --extra-index-url https://www.piwheels.org/simple

FROM debian:bullseye as runner
MAINTAINER sa2kng <knegge@gmail.com>

RUN apt-get -y update && apt-get -y install wget gnupg lsb-release && rm -rf /var/lib/apt/lists/*
RUN echo "deb http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_11/ ./" > /etc/apt/sources.list.d/satnogs.list
RUN echo "deb http://archive.raspberrypi.org/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/raspi.list
RUN wget -qO - http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_11/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/satnogs.gpg
RUN wget -qO - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/raspi.gpg

RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends libhamlib-utils vorbis-tools unzip git python3-pip rtl-sdr satnogs-flowgraphs gr-soapy gr-satnogs libhdf5-103 python3-virtualenv virtualenv python3-libhamlib2 python3-six python3-requests soapysdr-module-all soapysdr-tools python3-construct jq soapysdr-module-plutosdr soapysdr-module-airspyhf python3-gps && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/bash -u 999 satnogs

WORKDIR /var/lib/satnogs
USER satnogs
RUN --mount=type=cache,id=wheels,target=/wheels virtualenv -p python3 --system-site-packages . && . bin/activate && pip3 install satnogs-client~=1.8 --find-links=/wheels --prefix=/var/lib/satnogs --no-index && rm -rf .cache/pip/
RUN mkdir -p .gnuradio/prefs/ && echo -n "gr::vmcircbuf_sysv_shm_factory" > .gnuradio/prefs/vmcircbuf_default_factory

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["satnogs-client"]

