# syntax = docker/dockerfile:1.2
FROM debian:bullseye as builder

ARG GRSATNOGS_URL=https://gitlab.com/knegge/gr-satnogs.git
ARG GRSATNOGS_BRANCH=master
ARG FLOWGRAPHS_URL=https://gitlab.com/knegge/satnogs-flowgraphs.git
ARG FLOWGRAPHS_BRANCH=ssb
ARG CLIENT_GIT=git+https://gitlab.com/knegge/satnogs-client.git@ssb

RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends unzip git python3-pip libhdf5-103 python3-virtualenv virtualenv build-essential gfortran pkg-config libhdf5-dev python3-dev python3-libhamlib2 python3-gps

RUN apt -y install --no-install-recommends cmake debhelper dh-python doxygen git gnuradio-dev \
libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev nlohmann-json3-dev liborc-0.4-dev libpng++-dev \
libvorbis-dev libitpp-dev pkg-config python3-dev python3-six swig python3-all gr-soapy python3-soapysdr

RUN git clone --depth 1 --branch $GRSATNOGS_BRANCH $GRSATNOGS_URL
RUN sed -i 's/0.0-1/2.3-1/g' gr-satnogs/debian/changelog
RUN cd gr-satnogs && sed -i 's/0.0-1/2.3-1/g' debian/changelog && ./debian/rules binary
RUN dpkg -i gr-satnogs_*.deb libgnuradio-satnogs_*.deb

RUN git clone --depth 1 --branch $FLOWGRAPHS_BRANCH $FLOWGRAPHS_URL
RUN cd satnogs-flowgraphs && sed -i 's/0.0-1/1.4-1/g' debian/changelog && ./debian/rules binary
RUN dpkg -i satnogs-flowgraphs_*.deb

WORKDIR /env
RUN virtualenv -p python3 --no-seed .
RUN . bin/activate && pip3 install --upgrade pip setuptools wheel ujson --prefer-binary --extra-index-url https://www.piwheels.org/simple
RUN --mount=type=cache,id=wheels,target=/wheels . bin/activate && pip3 wheel $CLIENT_GIT -w /wheels --prefer-binary --extra-index-url https://www.piwheels.org/simple

FROM debian:bullseye as runner
MAINTAINER sa2kng <knegge@gmail.com>

RUN apt-get -y update && apt-get -y install wget gnupg lsb-release && rm -rf /var/lib/apt/lists/*
RUN echo "deb http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_11/ ./" > /etc/apt/sources.list.d/satnogs.list
RUN echo "deb http://archive.raspberrypi.org/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/raspi.list
RUN wget -qO - http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_11/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/satnogs.gpg
RUN wget -qO - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/raspi.gpg

RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends libhamlib-utils vorbis-tools unzip git python3-pip rtl-sdr satnogs-flowgraphs gr-soapy gr-satnogs libhdf5-103 python3-virtualenv virtualenv python3-libhamlib2 python3-six python3-requests soapysdr-module-all soapysdr-tools python3-construct jq soapysdr-module-plutosdr soapysdr-module-airspyhf python3-gps && rm -rf /var/lib/apt/lists/*

COPY --from=builder /*.deb /
RUN dpkg -i gr-satnogs_*.deb libgnuradio-satnogs_*.deb satnogs-flowgraphs_*.deb

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/bash -u 999 satnogs

WORKDIR /var/lib/satnogs
USER satnogs
RUN --mount=type=cache,id=wheels,target=/wheels virtualenv -p python3 --system-site-packages . && . bin/activate && pip3 install satnogs-client~=1.8 --find-links=/wheels --prefix=/var/lib/satnogs --no-index && rm -rf .cache/pip/
RUN mkdir -p .gnuradio/prefs/ && echo -n "gr::vmcircbuf_sysv_shm_factory" > .gnuradio/prefs/vmcircbuf_default_factory

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["satnogs-client"]

