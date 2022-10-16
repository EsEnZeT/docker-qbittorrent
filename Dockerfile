FROM alpine:edge as build

ARG QBT_VERSION=release-4.4.5
ARG LT_VERSION=v1.2.17

WORKDIR /build

RUN \
  apk add --no-cache --upgrade \
    bash \
    curl && \
  curl -sL git.io/qbstatic | bash -s all -qt ${QBT_VERSION} -lt ${LT_VERSION} -i -c -o


FROM ghcr.io/linuxserver/baseimage-alpine:edge

# set version args
ARG QBT_CLI_VERSION=v1.7.22220.1
ARG UNRAR_VERSION=6.1.7

# environment settings
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

# install runtime packages and qbitorrent-cli
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    jq \
    make \
    g++ \
    gcc && \
  echo "**** install packages ****" && \
  apk add -U --update --no-cache \
    icu-libs \
    libstdc++ \
    openssl \
    p7zip \
    python3 && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/bin && \
  echo "***** install qbitorrent-cli ****" && \
  mkdir /qbt && \
  QBT_CLI_VERSION=$(curl -sL "https://api.github.com/repos/fedarovich/qbittorrent-cli/releases" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  curl -o \
    /tmp/qbt.tar.gz -L \
    "https://github.com/fedarovich/qbittorrent-cli/releases/download/${QBT_CLI_VERSION}/qbt-linux-alpine-x64-${QBT_CLI_VERSION:1}.tar.gz" && \
  tar xf \
    /tmp/qbt.tar.gz -C \
    /qbt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# add qbittorrent-nox
COPY --from=build /build/qbt-build/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8080 6881 6881/udp

VOLUME /config
