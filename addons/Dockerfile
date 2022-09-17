FROM knegge/satnogs-client:latest AS builder
WORKDIR /
USER root

# install build env and required libs etc
RUN apt update && apt install -y swig feh cmake build-essential gnuradio-dev libusb-1.0-0-dev libsoapysdr-dev libpng-dev libsndfile-dev fakeroot psmisc ninja-build autoconf automake libtool patch

# install everything in /target and it will go in to / on destination image. symlink make it easier for builds to find files installed by this.
RUN mkdir -p /target/usr && rm -rf /usr/local && ln -sf /target/usr /usr/local

# install gr-satellites
RUN git clone -b maint-3.8 --depth=1 https://github.com/daniestevez/gr-satellites.git
RUN cd gr-satellites &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr &&\
    cmake --build build --target install

# install satnogs_gr-satellites
RUN git clone --depth=1 https://github.com/kng/satnogs_gr-satellites.git
RUN cd satnogs_gr-satellites &&\
    make DESTDIR=/target PREFIX=/usr install

# install mirisdr
RUN git clone -b v2.0.0 https://github.com/f4exb/libmirisdr-4.git
RUN cd libmirisdr-4 &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr &&\
    cmake --build build --target install

# install soapymiri
RUN git clone https://github.com/ericek111/SoapyMiri.git
RUN cd SoapyMiri &&\
    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
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

# test run flowgraph with current settings
COPY test-flowgraph.sh /target/usr/bin
COPY wf2png.py /target/usr/bin

ENTRYPOINT []
CMD ["bash"]

FROM knegge/satnogs-client:latest
COPY --from=builder /target /

