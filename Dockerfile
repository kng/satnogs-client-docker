FROM debian:buster
MAINTAINER sa2kng <knegge@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install wget gnupg
RUN echo deb http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_10/ ./> /etc/apt/sources.list.d/satnogs.list
RUN wget -qO - http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_10/Release.key | DEBIAN_FRONTEND=noninteractive apt-key --keyring /etc/apt/trusted.gpg.d/satnogs.gpg add -

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor software-properties-common libhamlib-utils vorbis-tools unzip git python3-pip python3-urllib3 python3-certifi python3-chardet python3-cycler python3-decorator python3-idna python3-kiwisolver python3-pyparsing python3-tz python3-tzlocal python3-libhamlib2 rtl-sdr satnogs-flowgraphs gr-soapy gr-satnogs
RUN pip3 install satnogs-client

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/false -u 999 satnogs
ADD entrypoint.sh /

WORKDIR /var/lib/satnogs
USER satnogs
RUN mkdir -p /var/lib/satnogs/.gnuradio/prefs/ && echo -n "gr::vmcircbuf_mmap_shm_open_factory" > /var/lib/satnogs/.gnuradio/prefs/vmcircbuf_default_factory

ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["satnogs-client"]

