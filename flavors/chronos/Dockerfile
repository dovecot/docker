ARG BASE_IMAGE_PREFIX=dovecot/dovecot:
ARG BASE_TAG=2.4.1
ARG BUILD_IMAGE=${BASE_IMAGE_PREFIX}${BASE_TAG}-build
ARG RUNTIME_ROOT_IMAGE=${BASE_IMAGE_PREFIX}${BASE_TAG}-root
ARG RUNTIME_DEV_IMAGE=${BASE_IMAGE_PREFIX}${BASE_TAG}-dev
ARG RUNTIME_PROD_IMAGE=${BASE_IMAGE_PREFIX}${BASE_TAG}

# Stage 1: Build the chronos plugin against the base build image
FROM ${BUILD_IMAGE} AS chronos-builder

ARG FLAVOR_REPO_URL=https://github.com/dovecot/push-notification-plugin-chronos
ARG FLAVOR_BRANCH=main
ARG CFLAGS
ARG LDFLAGS

USER nobody
WORKDIR /build/chronos
RUN (git clone --depth 1 --single-branch -b ${BASE_TAG} ${FLAVOR_REPO_URL} .) || \
    git clone --depth 1 --single-branch -b ${FLAVOR_BRANCH} ${FLAVOR_REPO_URL} .
RUN ./autogen.sh
RUN env CFLAGS="$CFLAGS -ffile-prefix-map=$PWD=." LDFLAGS="$LDFLAGS" CXXFLAGS="$CFLAGS -ffile-prefix-map=$PWD=. " \
    ./configure \
    --with-dovecot=/build/core \
    --prefix=/dovecot \
    --sysconfdir=/etc \
    --disable-rpath \
    --disable-static
RUN make -j V=0
USER root
RUN make install-strip DESTDIR=/build/install-root

# Target: chronos-root (root execution target)
FROM ${RUNTIME_ROOT_IMAGE} AS chronos-root
COPY --from=chronos-builder /build/install-root/dovecot /dovecot
COPY config/90-push-notification-chronos.conf /etc/dovecot/conf.d/90-push-notification-chronos.conf
USER root

# Target: chronos-dev (rootless dev target with debugging utilities)
FROM ${RUNTIME_DEV_IMAGE} AS chronos-dev
COPY --from=chronos-builder /build/install-root/dovecot /dovecot
COPY config/90-push-notification-chronos.conf /etc/dovecot/conf.d/90-push-notification-chronos.conf
USER vmail

# Target: chronos (minimal production target)
FROM ${RUNTIME_PROD_IMAGE} AS chronos
COPY --from=chronos-builder /build/install-root/dovecot /dovecot
COPY config/90-push-notification-chronos.conf /etc/dovecot/conf.d/90-push-notification-chronos.conf
USER vmail
