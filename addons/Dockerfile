ARG SATNOGS_IMAGE_TAG=master
ARG REPO_ROOT=librespace
ARG RUST_IMAGE_TAG=bullseye

FROM ${REPO_ROOT}/satnogs-client:${SATNOGS_IMAGE_TAG} AS builder
WORKDIR /usr/src
USER root

# install build env and required libs etc
COPY packages.builder .
RUN apt -y update && \
    xargs -a packages.builder apt install -qy

# install everything in /target and it will go in to / on destination image. symlink make it easier for builds to find files installed by this.
RUN mkdir -p /target/usr && rm -rf /usr/local && ln -sf /target/usr /usr/local

ARG CMAKE_BUILD_PARALLEL_LEVEL

# install gr-satellites, this is now included in the base image
#RUN git clone -b maint-3.8 --depth=1 https://github.com/daniestevez/gr-satellites.git
#RUN cd gr-satellites &&\
#    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr &&\
#    cmake --build build --target install

# install beesat-sdr for mobitex support
RUN git clone -b maint-3.8 --depth=1 https://github.com/daniestevez/beesat-sdr.git
RUN cd beesat-sdr/gr-tnc_nx &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# SSDV with support for DSLWP and JY1SAT modes
RUN git clone --depth=1 https://github.com/daniestevez/ssdv.git
RUN cd ssdv &&\
    make DESTDIR=/target install

# install satnogs_gr-satellites, also implemented in grsat.py
#RUN git clone --depth=1 https://github.com/kng/satnogs_gr-satellites.git
#RUN cd satnogs_gr-satellites &&\
#    make DESTDIR=/target PREFIX=/usr install

# install mirisdr
RUN git clone https://github.com/ericek111/libmirisdr-5.git
RUN cd libmirisdr-5 &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# install soapymiri
RUN git clone https://github.com/ericek111/SoapyMiri.git
RUN cd SoapyMiri &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr/local -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# SDRplay services install
RUN MAJVERS=3 &&\
    VERS=3.15 &&\
    MINVERS=2 &&\
    BINARY=SDRplay_RSP_API-Linux-${VERS}.${MINVERS}.run &&\
    case $(uname -m) in\
      aarch64) DIR=arm64 ;;\
      armv*) DIR=armhf ;;\
      *) DIR=amd64 ;;\
    esac &&\
    curl --no-keepalive -o sdrplay_api https://www.sdrplay.com/software/${BINARY} &&\
    sh ./sdrplay_api --noexec --target sdrplay &&\
    install -m 755 sdrplay/${DIR}/sdrplay_apiService /target/usr/bin/ &&\
    install -m 644 sdrplay/inc/sdrplay_api*.h /target/usr/include/ &&\
    install -m 644 sdrplay/${DIR}/libsdrplay_api.so.${VERS} /target/usr/lib/ &&\
    ln -sf libsdrplay_api.so.${VERS} /target/usr/lib/libsdrplay_api.so.${MAJVERS} &&\
    ln -sf libsdrplay_api.so.${MAJVERS} /target/usr/lib/libsdrplay_api.so &&\
    ldconfig

# SoapySDRPlay3 from pothosware
RUN git clone --depth=1 -b soapy-sdrplay3-0.5.1 https://github.com/pothosware/SoapySDRPlay3.git
RUN cd SoapySDRPlay3 &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr/local -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# SoapyRTLTCP from pothosware
RUN git clone --depth=1 https://github.com/pothosware/SoapyRTLTCP.git
RUN cd SoapyRTLTCP &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr/local -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# install aptdec
RUN git clone --recursive https://github.com/Xerbo/aptdec.git
RUN cd aptdec &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# fpc is a quite big install, build meted
##RUN apt install -y fpc --no-install-recommends
#RUN git clone https://github.com/artlav/meteor_decoder.git
#RUN cd meteor_decoder && mkdir units &&\
#    fpc -CX -XX -O3 -Mdelphi -FUunits -Fualib medet.dpr &&\
#    cp medet /target/usr/bin

# satellite orbit prediction for tle
RUN git clone -b v2.0.0 https://github.com/la1k/libpredict.git
RUN cd libpredict &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# needs qt5 in base image ?
#RUN apt install -y qtbase5-dev libmuparser-dev libshp-dev
#RUN git clone https://github.com/Xerbo/LeanHRPT-Decode.git
#RUN cd LeanHRPT-Decode &&\
#    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr &&\
#    cmake --build build --target install

# kalibrate for rtl_sdr
RUN git clone https://github.com/steve-m/kalibrate-rtl.git
RUN cd kalibrate-rtl &&\
    ./bootstrap &&\
    CXXFLAGS='-W -Wall -O3' ./configure &&\
    make &&\
    cp src/kal /target/usr/bin

# rx_fm rx_power rx_sdr
RUN git clone --depth=1 https://github.com/rxseger/rx_tools.git
RUN cd rx_tools &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# rffft from strf
RUN git clone --depth=1 https://github.com/cbassa/strf.git
RUN cd strf && make rffft && cp rffft /target/usr/bin

# Meteor-M2 series demodulator
RUN git clone --depth=1 https://github.com/dbdexter-dev/meteor_demod.git
RUN cd meteor_demod &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# Meteor-M series LRPT decoder
RUN git clone --depth=1 https://github.com/dbdexter-dev/meteor_decode.git
RUN cd meteor_decode &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# libgpredict
RUN git clone --depth=1 https://github.com/cubehub/libgpredict.git
RUN cd libgpredict &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# URESAT-1 decoder
RUN git clone --depth=1 https://github.com/AMSAT-EA/URESAT-1-decoder.git
RUN cd URESAT-1-decoder/bit-version/linux &&\
    make &&\
    install -m 755 uresat-decoder-linux-x86 /target/usr/bin

# SatDump CLI, disabled by default as it is a lengthy build
ARG BUILD_SATDUMP
RUN if [ -n "$BUILD_SATDUMP" ]; then \
        git clone --depth=1 https://github.com/SatDump/SatDump.git &&\
        cd SatDump &&\
        cmake -B build \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_STAGING_PREFIX=/target/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_GUI=OFF \
            -DPLUGIN_SCRIPTING=ON \
            -DBUILD_TOOLS=ON &&\
        cmake --build build --target install ;\
    fi

ARG SATNOGS_CLIENT_VARSTATEDIR=/var/lib/satnogs-client
# UDP client for programs that require data on stdin
COPY gnuradio/*.conf /target/etc/gnuradio/conf.d/
COPY grc/*.grc .
RUN grcc -o /target/usr/bin/ *.grc

COPY scripts/* /target/usr/bin/
COPY satyaml/* /target/usr/lib/python3/dist-packages/satellites/satyaml/
COPY --chown=satnogs-client:satnogs-client direwolf.conf /target/etc/
COPY --chown=satnogs-client:satnogs-client sat.cfg /target/$SATNOGS_CLIENT_VARSTATEDIR/.gr_satellites/sat.cfg
COPY --chown=satnogs-client:satnogs-client satdump_cfg.json /target/$SATNOGS_CLIENT_VARSTATEDIR/.config/satdump/satdump_cfg.json
# Don't rely on repository file permissions, COPY --chmod requires BuildKit
RUN chmod 0755 /target/usr/bin/*

ENTRYPOINT []
CMD ["bash"]


FROM rust:${RUST_IMAGE_TAG} AS rust
WORKDIR /usr/src
USER root

ARG DEBIAN_FRONTEND=noninteractive
# install build env and required libs etc
COPY packages.rust .
RUN apt -y update && \
    xargs -a packages.rust apt install -qy

# install everything in /target and it will go in to / on destination image
RUN mkdir -p /target/usr/bin

ARG CMAKE_BUILD_PARALLEL_LEVEL

# libgpredict
RUN git clone --depth=1 https://github.com/cubehub/libgpredict.git
RUN cd libgpredict &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release &&\
    cmake --build build --target install

# satnogs-monitor
RUN git clone --depth=1 https://github.com/wose/satnogs-monitor.git
RUN cd satnogs-monitor/monitor &&\
    cargo update &&\
    cargo build --release &&\
    cp ../target/release/satnogs-monitor /target/usr/bin/


FROM ${REPO_ROOT}/satnogs-client:${SATNOGS_IMAGE_TAG} AS runner
LABEL org.opencontainers.image.authors="Daniel Ekman <knegge@gmail.com>"

WORKDIR /usr/src
COPY packages.client .
RUN apt -y update && \
    xargs -a packages.client apt install -qy && \
    rm -rf /var/lib/apt/lists/*

# install python packages
COPY packages.pip .
RUN xargs -a packages.pip pip install

# copy the files built
COPY --from=builder /target /
COPY --from=rust /target /

RUN chown -R satnogs-client:satnogs-client /usr/lib/python3/dist-packages/satellites/satyaml
ARG SATNOGS_CLIENT_VARSTATEDIR=/var/lib/satnogs-client
WORKDIR $SATNOGS_CLIENT_VARSTATEDIR

