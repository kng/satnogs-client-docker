ARG GNURADIO_IMAGE_TAG=3.8.2.0-satnogs
ARG REPO_ROOT=librespace
FROM ${REPO_ROOT}/gnuradio:${GNURADIO_IMAGE_TAG} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

WORKDIR /usr/local/src/
COPY packages.builder .
RUN apt -y update && \
    apt -y upgrade && \
    xargs -a packages.builder apt install --no-install-recommends -qy

ARG GRSATNOGS_URL=https://gitlab.com/librespacefoundation/satnogs/gr-satnogs.git
ARG GRSATNOGS_BRANCH=v2.3.5.0
ARG GRSATNOGS_VER=2.3.5.0-1
ARG FLOWGRAPHS_URL=https://gitlab.com/librespacefoundation/satnogs/satnogs-flowgraphs.git
ARG FLOWGRAPHS_BRANCH=1.5
ARG FLOWGRAPHS_VER=1.5-1
ARG GRSOAPY_URL=https://gitlab.com/librespacefoundation/gr-soapy.git
ARG GRSOAPY_BRANCH=v2.1.3.1
ARG GRSOAPY_VER=2.1.3.1-1
ARG CLIENT_URL=https://gitlab.com/librespacefoundation/satnogs/satnogs-client.git
ARG CLIENT_BRANCH=1.9.2
ARG CLIENT_VER=1.9.2

RUN git clone --depth 1 --branch "$GRSATNOGS_BRANCH" "$GRSATNOGS_URL"
RUN git clone --depth 1 --branch "$FLOWGRAPHS_BRANCH" "$FLOWGRAPHS_URL"
RUN git clone --depth 1 --branch "$GRSOAPY_BRANCH" "$GRSOAPY_URL"
RUN git clone --depth 1 --branch "$CLIENT_BRANCH" "$CLIENT_URL"

ARG CMAKE_BUILD_PARALLEL_LEVEL

ARG RTLSDR_URL
ARG RTLSDR_BRANCH=master
ARG RTLSDR_VER=0.6.0-3satnogs1
RUN if [ -n "$RTLSDR_URL" ]; then \
        git clone --depth 1 --branch "$RTLSDR_BRANCH" "$RTLSDR_URL" rtl-sdr && \
        cd rtl-sdr && \
        dch -m -b --distribution unstable -v $RTLSDR_VER Upstream master && \
        DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
        dpkg -i ../rtl-sdr_*.deb ../librtlsdr0_*.deb ;\
    fi

RUN cd gr-soapy && \
    dch -m -b --distribution unstable -v $GRSOAPY_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../gr-soapy_*.deb ../libgnuradio-soapy_*.deb

RUN cd gr-satnogs && \
    dch -m -b --distribution unstable -v $GRSATNOGS_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../gr-satnogs_*.deb ../libgnuradio-satnogs_*.deb

RUN cd satnogs-flowgraphs && \
    dch -m -b --distribution unstable -v $FLOWGRAPHS_VER Upstream master && \
    DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc && \
    dpkg -i ../satnogs-flowgraphs_*.deb

ARG UHD_URL
RUN if [ -n "$UHD_URL" ]; then \
      dget -q -u "$UHD_URL" &&\
      cd uhd-* &&\
      DEB_BUILD_OPTIONS=noautodbgsym dpkg-buildpackage -b -us -uc --build=binary &&\
      cd .. &&\
      rm -f libuhd*dpdk* libuhd-dev* uhd-doc* &&\
      dpkg -i uhd-host_*.deb libuhd*.deb ;\
    fi

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
ARG REPO_ROOT=librespace
FROM ${REPO_ROOT}/gnuradio:${GNURADIO_IMAGE_TAG} AS runner
LABEL org.opencontainers.image.authors="Daniel Ekman <knegge@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# make this depend on builder
COPY --from=builder /etc/pip.conf /etc

# Install deb packages from builder and optional repo
ARG OBS_REPO
COPY packages.client /usr/local/src/
RUN --mount=type=cache,id=debs,target=/debs \
    if [ -n "${OBS_REPO}" ]; then \
      echo "deb ${OBS_REPO} /" > /etc/apt/sources.list.d/obs_repo.list &&\
	  apt-key adv --fetch-keys "${OBS_REPO}/Release.key"; \
    fi &&\
    apt -y update && \
    apt -y upgrade && \
    xargs -a /usr/local/src/packages.client apt install -qy python3-pip && \
    apt install -qy --allow-downgrades /debs/$(dpkg --print-architecture)/*.deb && \
    apt -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# Install python packages from builder
RUN --mount=type=cache,id=wheels,target=/wheels \
    pip3 install --no-cache --find-links=/wheels --no-index satnogs-client

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

# Restore permissions on satyaml dir
RUN chown -R satnogs-client:satnogs-client /usr/lib/python3/dist-packages/satellites/satyaml

ARG UHD_URL
RUN if [ -n "$UHD_URL" ]; then \
        uhd_images_downloader -q ;\
    fi

WORKDIR $SATNOGS_CLIENT_VARSTATEDIR

