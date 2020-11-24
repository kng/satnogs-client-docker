FROM debian:buster
MAINTAINER sa2kng <knegge@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install wget gnupg && rm -rf /var/lib/apt/lists/*
RUN echo deb http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_10/ ./> /etc/apt/sources.list.d/satnogs.list
RUN wget -qO - http://download.opensuse.org/repositories/home:/librespace:/satnogs/Debian_10/Release.key | DEBIAN_FRONTEND=noninteractive apt-key --keyring /etc/apt/trusted.gpg.d/satnogs.gpg add -

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor software-properties-common libhamlib-utils vorbis-tools unzip git python3-pip python3-urllib3 python3-certifi python3-chardet python3-cycler python3-decorator python3-idna python3-kiwisolver python3-pyparsing python3-tz python3-tzlocal python3-libhamlib2 rtl-sdr satnogs-flowgraphs gr-soapy gr-satnogs && rm -rf /var/lib/apt/lists/*
#RUN pip3 install satnogs-client

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/false -u 999 satnogs
ADD supervisord.conf /etc/supervisor/supervisord.conf
#RUN echo "#!/bin/bash\n/usr/bin/rigctld -T 127.0.0.1 -m 1 &\n/usr/local/bin/satnogs-client" >> /usr/local/bin/satnogs-run.sh  && chmod 0755 /usr/local/bin/satnogs-run.sh
RUN echo "#!/bin/bash\n/usr/bin/rigctld -T 127.0.0.1 -m 1 &\n/var/lib/satnogs/.local/bin/satnogs-client" >> /usr/local/bin/satnogs-run.sh && chmod 0755 /usr/local/bin/satnogs-run.sh
WORKDIR /var/lib/satnogs
USER satnogs
RUN pip3 install satnogs-client
RUN mkdir -p /var/lib/satnogs/.gnuradio/prefs/ && echo -n "gr::vmcircbuf_mmap_shm_open_factory" > /var/lib/satnogs/.gnuradio/prefs/vmcircbuf_default_factory
#RUN volk_profile

# choose to simply fork the rigctld in background and satnogs-client in foreground, or use supervisord for the two
CMD ["/usr/bin/supervisord","-c/etc/supervisor/supervisord.conf"]
#CMD ["/usr/local/bin/satnogs-run.sh"]

