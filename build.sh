#!/usr/bin/env bash

set -eux

VERSION=${VERSION-2.4.1}
DOVECOT_REPO_URL=${DOVECOT_REPO_URL-https://github.com/dovecot/core}
PIGEONHOLE_REPO_URL=${PIGEONHOLE_REPO_URL-https://github.com/dovecot/pigeonhole}
DOVECOT_BRANCH=${DOVECOT_BRANCH-$VERSION}
PIGEONHOLE_BRANCH=${PIGEONHOLE_BRANCH-$VERSION}

amd64_CFLAGS="-g -O2 -mtune=generic -mavx -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-clash-protection -fcf-protection"
arm64_CFLAGS="-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-clash-protection -mharden-sls=all -mbranch-protection=standard"

amd64_LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects"
arm64_LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects"

for PLATFORM in arm64; do
	for stage in "-build" "-root" "-dev" ""; do
		PLATFORM_CFLAGS="${PLATFORM}_CFLAGS"
		PLATFORM_LDFLAGS="${PLATFORM}_LDFLAGS"
		docker buildx build --platform $PLATFORM \
			--build-arg CFLAGS="${!PLATFORM_CFLAGS}" --build-arg LDFLAGS="${!PLATFORM_LDFLAGS}" \
			--build-arg DOVECOT_REPO_URL=$DOVECOT_REPO_URL --build-arg DOVECOT_BRANCH=$DOVECOT_BRANCH \
			--build-arg PIGEONHOLE_REPO_URL=$PIGEONHOLE_REPO_URL --build-arg PIGEONHOLE_BRANCH=$DOVECOT_BRANCH \
			--target production$stage --tag dovecot/dovecot:$VERSION${stage}-$PLATFORM $VERSION
	done
done
