#!/usr/bin/env bash

set -eux

# Set default values
VERSION=${VERSION-2.4.1}
DOVECOT_REPO_URL=${DOVECOT_REPO_URL-https://github.com/dovecot/core}
PIGEONHOLE_REPO_URL=${PIGEONHOLE_REPO_URL-https://github.com/dovecot/pigeonhole}
DOVECOT_BRANCH=${DOVECOT_BRANCH-$VERSION}
PIGEONHOLE_BRANCH=${PIGEONHOLE_BRANCH-$VERSION}

# Detect architecture
ARCH=$(uname -m)

# Check for AVX support
if cat /proc/cpuinfo | grep -i avx; then
    AVX_FLAG="-mavx"
else
    AVX_FLAG=""
fi

# Set flags based on architecture
if [[ "$ARCH" == "x86_64" ]]; then
    PLATFORM="amd64"
    CFLAGS="-g -O2 -mtune=generic $AVX_FLAG -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-clash-protection -fcf-protection"
    LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects"
elif [[ "$ARCH" == "aarch64" ]]; then
    PLATFORM="arm64"
    CFLAGS="-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-clash-protection -mharden-sls=all -mbranch-protection=standard"
    LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Build the Docker image
for stage in "-build" "-root" "-dev" ""; do
    docker buildx build --platform $PLATFORM \
        --build-arg CFLAGS="$CFLAGS" --build-arg LDFLAGS="$LDFLAGS" \
        --build-arg DOVECOT_REPO_URL=$DOVECOT_REPO_URL --build-arg DOVECOT_BRANCH=$DOVECOT_BRANCH \
        --build-arg PIGEONHOLE_REPO_URL=$PIGEONHOLE_REPO_URL --build-arg PIGEONHOLE_BRANCH=$DOVECOT_BRANCH \
        --target production$stage --tag dovecot/dovecot:$VERSION${stage}-$PLATFORM $VERSION
done
