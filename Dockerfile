# satnogs-client 1.8
FROM debian:bullseye
MAINTAINER sa2kng <knegge@gmail.com>

RUN apt-get -y update && apt-get -y install wget gnupg && rm -rf /var/lib/apt/lists/*
RUN echo "deb http://download.opensuse.org/repositories/home:/librespace:/satnogs/$(if arch | grep -q "armv"; then echo "Raspbian"; else echo "Debian"; fi)_11/ ./" > /etc/apt/sources.list.d/satnogs.list
RUN wget -qO - http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_11/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/satnogs.gpg

RUN apt-get -y update && apt-get -y install --no-install-recommends libhamlib-utils vorbis-tools unzip git python3-pip rtl-sdr satnogs-flowgraphs gr-soapy gr-satnogs libhdf5-103 python3-virtualenv virtualenv python3-libhamlib2 python3-six soapysdr-module-all soapysdr-tools python3-construct jq && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/bash -u 999 satnogs

WORKDIR /var/lib/satnogs
USER satnogs
RUN virtualenv -p python3 --system-site-packages . && . bin/activate && pip3 install satnogs-client~=1.8 gps==3.19 --prefix=/var/lib/satnogs --prefer-binary --extra-index-url https://www.piwheels.org/simple && rm -rf .cache/pip/
#RUN mkdir -p /var/lib/satnogs/.gnuradio/prefs/ && echo -n "gr::vmcircbuf_mmap_shm_open_factory" > /var/lib/satnogs/.gnuradio/prefs/vmcircbuf_default_factory
#RUN mkdir -p /var/lib/satnogs/.gnuradio/prefs/ && echo -n "gr::vmcircbuf_sysv_shm_factory" > /var/lib/satnogs/.gnuradio/prefs/vmcircbuf_default_factory

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["satnogs-client"]

