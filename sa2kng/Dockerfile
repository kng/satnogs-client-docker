ARG GNURADIO_IMAGE_TAG=satnogs
FROM librespace/gnuradio:${GNURADIO_IMAGE_TAG} as builder

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

WORKDIR /usr/local/src/
COPY packages.builder .
RUN apt -y update && \
    apt -y upgrade && \
    xargs -a packages.builder apt install --no-install-recommends -qy

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
ARG CLIENT_VER=1.8.1
ARG RTLSDR_URL=
ARG RTLSDR_BRANCH=

RUN git clone --depth 1 --branch "$GRSATNOGS_BRANCH" "$GRSATNOGS_URL"
RUN git clone --depth 1 --branch "$FLOWGRAPHS_BRANCH" "$FLOWGRAPHS_URL"
RUN git clone --depth 1 --branch "$GRSOAPY_BRANCH" "$GRSOAPY_URL"
RUN git clone --depth 1 --branch "$CLIENT_BRANCH" "$CLIENT_URL"

RUN if [ -n "$RTLSDR_URL" ]; then \
        if [ -z "$RTLSDR_BRANCH" ]; then RTLSDR_BRANCH="master"; fi ;\
        git clone --depth 1 --branch "$RTLSDR_BRANCH" "$RTLSDR_URL" rtl-sdr && \
        cd rtl-sdr && \
        dch -m --distribution unstable --local .0-4sa2kng Upstream master && \
        DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
        dpkg -i ../rtl-sdr_*.deb ../librtlsdr0_*.deb ;\
    fi

RUN cd gr-soapy && \
    dch -m --distribution unstable -v $GRSOAPY_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../gr-soapy_*.deb ../libgnuradio-soapy_*.deb

RUN cd gr-satnogs && \
    dch -m --distribution unstable -v $GRSATNOGS_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../gr-satnogs_*.deb ../libgnuradio-satnogs_*.deb

RUN cd satnogs-flowgraphs && \
    dch -m --distribution unstable -v $FLOWGRAPHS_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../satnogs-flowgraphs_*.deb

RUN --mount=type=cache,id=debs,target=/debs \
    mkdir -p /debs/$(dpkg --print-architecture)/ && \
    rm -f /debs/$(dpkg --print-architecture)/* && \
    cp *.deb /debs/$(dpkg --print-architecture)/

ARG MPLSETUPCFG=/etc/mplsetup.cfg
RUN --mount=type=cache,id=wheels,target=/wheels \
    printf "[libs]\nsystem_freetype = true" > $MPLSETUPCFG && \
    printf "[global]\nextra-index-url=https://www.piwheels.org/simple" > /etc/pip.conf && \
    rm -f /wheels/satnogs* && \
    pip3 install --upgrade pip setuptools wheel ujson --find-links=/wheels --prefer-binary && \
    pip3 wheel -w /wheels --find-links=/wheels --prefer-binary \
    -r ./satnogs-client/requirements.txt \
    ./satnogs-client


ARG GNURADIO_IMAGE_TAG=satnogs
FROM librespace/gnuradio:${GNURADIO_IMAGE_TAG} as runner
MAINTAINER sa2kng <knegge@gmail.com>

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# make this depend on builder
ARG MPLSETUPCFG=/etc/mplsetup.cfg
COPY --from=builder $MPLSETUPCFG $MPLSETUPCFG

COPY packages.client /usr/local/src/
RUN --mount=type=cache,id=debs,target=/debs \
    apt -y update && \
    apt -y upgrade && \
    xargs -a /usr/local/src/packages.client apt install -qy python3-pip && \
    apt install -qy --allow-downgrades /debs/$(dpkg --print-architecture)/*.deb && \
    rm -rf /var/lib/apt/lists/*

ARG SATNOGS_CLIENT_UID=999
ARG SATNOGS_CLIENT_VARSTATEDIR=/var/lib/satnogs-client

# Add unprivileged system user
RUN groupadd -r -g ${SATNOGS_CLIENT_UID} satnogs-client \
	&& useradd -r -u ${SATNOGS_CLIENT_UID} \
		-g satnogs-client \
		-d ${SATNOGS_CLIENT_VARSTATEDIR} \
		-s /bin/false \
		-G audio,dialout,plugdev \
		satnogs-client

# Create application varstate directory
RUN install -d -o ${SATNOGS_CLIENT_UID} -g ${SATNOGS_CLIENT_UID} ${SATNOGS_CLIENT_VARSTATEDIR}

# Install python packages from builder
RUN --mount=type=cache,id=wheels,target=/wheels \
    pip3 install --no-cache --find-links=/wheels --no-index satnogs-client

WORKDIR $SATNOGS_CLIENT_VARSTATEDIR

