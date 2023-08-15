#!/bin/bash
set -eu
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
BUILDX_VER=$(git ls-remote --sort -v:refname --tags https://github.com/docker/buildx.git|head -n 1|sed 's/^.*tags\///g')
COMPOSE_VER=$(git ls-remote --sort -v:refname --tags https://github.com/docker/compose.git|head -n 1|sed 's/^.*tags\///g')

case $(dpkg --print-architecture) in
arm64)
    BUILDX_URL="https://github.com/docker/buildx/releases/download/$BUILDX_VER/buildx-$BUILDX_VER.linux-arm64"
    COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VER/docker-compose-linux-aarch64"
    ;;
armhf)
    BUILDX_URL="https://github.com/docker/buildx/releases/download/$BUILDX_VER/buildx-$BUILDX_VER.linux-arm-v7"
    COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VER/docker-compose-linux-armv7"
    ;;
amd64)
    BUILDX_URL="https://github.com/docker/buildx/releases/download/$BUILDX_VER/buildx-$BUILDX_VER.linux-amd64"
    COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VER/docker-compose-linux-x86_64"
    ;;
*)
    echo "Unknown architecture, exiting."
    exit 1
    ;;
esac

echo "Updating docker compose to $COMPOSE_VER and buildx to $BUILDX_VER in $DOCKER_CONFIG ..."
mkdir -p "$DOCKER_CONFIG/cli-plugins"
rm -f "$DOCKER_CONFIG/cli-plugins/docker-buildx" "$DOCKER_CONFIG/cli-plugins/docker-compose"

curl --progress-bar -SL "$BUILDX_URL" -o "$DOCKER_CONFIG/cli-plugins/docker-buildx"
curl --progress-bar -SL "$COMPOSE_URL" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"

chmod 0755 "$DOCKER_CONFIG/cli-plugins/docker-buildx" "$DOCKER_CONFIG/cli-plugins/docker-compose"

docker buildx version
docker compose version
