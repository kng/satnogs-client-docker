ARG BASE_IMAGE=debian:bullseye
FROM $BASE_IMAGE as builder

ARG GRSATNOGS_URL=https://gitlab.com/librespacefoundation/satnogs/gr-satnogs.git
ARG GRSATNOGS_BRANCH=master
ARG GRSATNOGS_VER=2.3.4.0-1
ARG FLOWGRAPHS_URL=https://gitlab.com/librespacefoundation/satnogs/satnogs-flowgraphs.git
ARG FLOWGRAPHS_BRANCH=master
ARG FLOWGRAPHS_VER=1.5-1
ARG GRSOAPY_URL=https://gitlab.com/librespacefoundation/gr-soapy.git
ARG GRSOAPY_BRANCH=master
ARG GRSOAPY_VER=2.1.3.1-1
ARG CLIENT_URL=https://gitlab.com/librespacefoundation/satnogs/satnogs-client.git
ARG CLIENT_BRANCH=master

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY packages.builder /usr/src/
RUN apt -y update && \
    apt -y upgrade && \
    xargs -a /usr/src/packages.builder apt install --no-install-recommends -qy 

RUN git clone --depth 1 --branch $GRSATNOGS_BRANCH $GRSATNOGS_URL
RUN git clone --depth 1 --branch $FLOWGRAPHS_BRANCH $FLOWGRAPHS_URL
RUN git clone --depth 1 --branch $GRSOAPY_BRANCH $GRSOAPY_URL

RUN cd gr-soapy && \
    sed -i 's/0.0-1/2.1-1/g' debian/changelog && \
    ./debian/rules binary
RUN dpkg -i gr-soapy_*.deb libgnuradio-soapy_*.deb

RUN cd gr-satnogs && \
    sed -i 's/0.0-1/2.3-1/g' debian/changelog && \
    ./debian/rules binary
RUN dpkg -i gr-satnogs_*.deb libgnuradio-satnogs_*.deb

RUN cd satnogs-flowgraphs && \
    sed -i 's/0.0-1/1.5-1/g' debian/changelog && \
    ./debian/rules binary
RUN dpkg -i satnogs-flowgraphs_*.deb

RUN --mount=type=cache,id=debs,target=/debs mkdir -p /debs/$(dpkg --print-architecture)/ && cp gr-satnogs_*.deb libgnuradio-satnogs_*.deb gr-soapy_*.deb libgnuradio-soapy_*.deb satnogs-flowgraphs_*.deb /debs/$(dpkg --print-architecture)/

WORKDIR /env
RUN virtualenv -p python3 --no-seed .
RUN . bin/activate && \
    pip3 install --upgrade pip setuptools wheel ujson --prefer-binary --extra-index-url https://www.piwheels.org/simple
RUN --mount=type=cache,id=wheels,target=/wheels rm -f /wheels/satnogs* && \
    . bin/activate && \
    pip3 wheel git+$CLIENT_URL@$CLIENT_BRANCH -w /wheels --prefer-binary --extra-index-url https://www.piwheels.org/simple && \
    ls -l /wheels > /wheels.list

FROM $BASE_IMAGE as runner
MAINTAINER sa2kng <knegge@gmail.com>

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY packages.client /usr/src/
RUN apt -y update && \
    apt -y upgrade && \
    xargs -a /usr/src/packages.client apt install --no-install-recommends -qy && \
    rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,id=debs,target=/debs dpkg -R -i /debs/$(dpkg --print-architecture)/

RUN groupadd -g 995 satnogs && useradd -g satnogs -G dialout,plugdev -m -d /var/lib/satnogs -s /bin/bash -u 999 satnogs

WORKDIR /var/lib/satnogs
USER satnogs

RUN --mount=type=cache,id=wheels,target=/wheels virtualenv -p python3 --system-site-packages . && . bin/activate && pip3 install satnogs-client --find-links=/wheels --prefix=/var/lib/satnogs --no-index && rm -rf .cache/pip/

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["satnogs-client"]

