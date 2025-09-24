# syntax=docker/dockerfile:1
FROM debian:12-slim as production-build

ENV container=docker \
    LC_ALL=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ARG DOVECOT_REPO_URL=https://github.com/dovecot/core
ARG PIGEONHOLE_REPO_URL=https://github.com/dovecot/pigeonhole
ARG DOVECOT_VERSION=2.4.1
ARG PIGEONHOLE_VERSION=2.4.1
ARG DOVECOT_BRANCH=$DOVECOT_VERSION
ARG PIGEONHOLE_BRANCH=$PIGEONHOLE_VERSION
ARG CFLAGS
ARG LDFLAGS

RUN mkdir -p /build/
RUN mkdir -p /dovecot/
RUN chown nobody /build/
RUN chown nobody /dovecot
USER nobody
RUN touch /dovecot/built

FROM debian:12-slim as production-base

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"

ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/dovecot/lib
ENV PATH $PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive
ARG VMAIL_UID=1000
ARG VMAIL_GID=1000

COPY --link --from=production-build /dovecot /dovecot
RUN touch /dovecot/base && \
 rm -rf /etc/dovecot && \
 rm -rf /var/lib/apt/lists && \
 groupadd -g $VMAIL_GID vmail && \
 useradd -u $VMAIL_UID -g vmail -d /srv/mail -s /bin/sh vmail && \
 passwd -l vmail && \
 mkdir -p /run && \
 chmod 1777 /run && \
 mkdir /etc/dovecot && \
 mkdir /etc/dovecot/vendor.d && \
 mkdir /etc/dovecot/conf.d && \
 mkdir /etc/dovecot/ssl && \
 mkdir /srv/vmail -p && \
 mkdir /var/lib/dovecot

FROM production-base as production-root

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"
ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/dovecot/lib
ENV PATH $PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

RUN groupadd --system dovecot && \
 groupadd --system dovenull && \
 useradd -g dovecot --system dovecot && \
 useradd -g dovenull --system dovenull

COPY dovecot.conf /etc/dovecot/dovecot.conf

FROM production-base as production-dev

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"
ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/dovecot/lib
ENV PATH $PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

RUN touch /etc/dovecot/dev

FROM production-dev as production

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"
ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/dovecot/lib
ENV PATH $PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

RUN touch /etc/dovecot/rootless
