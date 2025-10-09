FROM debian:13-slim AS production-build

ENV container=docker \
    LC_ALL=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ARG DOVECOT_REPO_URL=https://github.com/dovecot/core
ARG PIGEONHOLE_REPO_URL=https://github.com/dovecot/pigeonhole
ARG DOVECOT_VERSION=2.4.2
ARG PIGEONHOLE_VERSION=2.4.2
ARG DOVECOT_BRANCH=$DOVECOT_VERSION
ARG PIGEONHOLE_BRANCH=$PIGEONHOLE_VERSION
ARG CFLAGS
ARG LDFLAGS

RUN mkdir /dovecot
RUN apt-get -y update
RUN apt-get -y install --no-install-recommends \
  git \
  build-essential \
  ca-certificates \
  make \
  autoconf \
  automake \
  libtool \
  gettext \
  pkg-config \
  bison \
  flex \
  devscripts \
  libssl-dev \
  libldap2-dev \
  libbz2-dev \
  zlib1g-dev \
  liblz4-dev \
  libzstd-dev \
  libcap-dev \
  libsodium-dev \
  libwrap0-dev \
  libpam-dev \
  libkrb5-dev \
  libpq-dev \
  libsqlite3-dev \
  libexpat1-dev \
  liblua5.3-dev \
  lua-json \
  lua-lpeg \
  lua-posix \
  libxapian-dev \
  libstemmer-dev \
  libsasl2-dev \
  libicu-dev \
  krb5-multidev \
  libdb-dev \
  libcurl4-gnutls-dev \
  libexpat-dev \
  libexttextcat-dev \
  autotools-dev \
  openssh-client \
  default-libmysqlclient-dev \
  wget
RUN [ $(uname -m) = x86_64 ] && apt-get -y install libunwind-dev || true
RUN mkdir -p /build/
RUN chown nobody /build/
RUN chown nobody /dovecot
USER nobody

WORKDIR /build/core
RUN git clone -b $DOVECOT_BRANCH $DOVECOT_REPO_URL .
RUN env VERSION=$DOVECOT_VERSION ./autogen.sh
RUN env CFLAGS="$CFLAGS -ffile-prefix-map=$PWD=." LDFLAGS="$LDFLAGS" CXXFLAGS="$CFLAGS -ffile-prefix-map=$PWD=. " \
    ./configure \
    --with-ldap=plugin \
    --with-sql=plugin \
    --with-lua=plugin \
    --with-pgsql \
    --with-mysql \
    --with-sqlite \
    --with-gssapi=plugin \
    --with-solr \
    --with-flatcurve \
    --with-icu \
    --with-lz4 \
    --with-zstd \
    --with-bzlib \
    --with-stemmer \
    --with-textcat \
    --with-libcap \
    --enable-experimental-mail-utf8 \
    --with-retpoline=thunk-inline \
    --prefix=/dovecot \
    --sysconfdir=/etc \
    --localstatedir=/run/dovecot/state \
    --with-statedir=/run/dovecot/state \
    --docdir=/usr/share/doc/dovecot-core \
    --with-moduledir=\${libdir}/dovecot/modules \
    --with-rundir=/run/dovecot \
    --disable-rpath \
    --disable-static

RUN make -j V=0
RUN make check || true
USER root
RUN make install-strip
USER nobody
WORKDIR /build/pigeonhole
RUN git clone -b $PIGEONHOLE_BRANCH $PIGEONHOLE_REPO_URL .
RUN env VERSION=$PIGEONHOLE_VERSION ./autogen.sh
RUN env CFLAGS="$CFLAGS -ffile-prefix-map=$PWD=." LDFLAGS="$LDFLAGS" CXXFLAGS="$CFLAGS -ffile-prefix-map=$PWD=. " \
    ./configure \
    --with-dovecot=/build/core \
    --with-ldap=plugin \
    --prefix=/dovecot \
    --sysconfdir=/etc \
    --docdir=\${prefix}/share/doc/dovecot-core \
    --localstatedir=/run/dovecot/state \
    --with-statedir=/run/dovecot/state \
    --with-rundir=/run/dovecot \
    --disable-rpath \
    --disable-static \
    --with-retpoline=thunk-inline \
    --with-unfinished-features

RUN make -j V=0
RUN make check || true
USER root
RUN make install-strip
RUN chown -R root:root /dovecot
RUN wget https://github.com/dovecot/imaptest/releases/download/latest/imaptest-$(uname -m)-debian-13 -O /dovecot/bin/imaptest
RUN chmod 0755 /dovecot/bin/imaptest

FROM debian:13-slim AS production-base

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"

ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC \
    PATH=$PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive
ARG VMAIL_UID=1000
ARG VMAIL_GID=1000

COPY --link --from=production-build /dovecot /dovecot

ADD dovecot-lib.conf /etc/ld.so.conf.d/dovecot-lib.conf
RUN apt-get -y update && \
  apt-get -y install --no-install-recommends \
  tini \
  pkg-config \
  ssl-cert \
  ucf \
  libldap2 \
  libldap-common \
  openssl \
  libsodium23 \
  libbz2-1.0 \
  libcrypt1 \
  libexttextcat-2.0-0 \
  libexttextcat-data \
  liblua5.3-0 \
  libpam-runtime \
  libpam-modules-bin \
  libpam-modules \
  libpam0g \
  lua-json \
  lua-lpeg \
  lua-posix \
  liblz4-1 \
  liblzma5 \
  libssl3 \
  libstemmer0d \
  libtirpc3 \
  libunwind8 \
  libwrap0 \
  libzstd1 \
  zlib1g \
  libgssapi-krb5-2 \
  libkrb5-3 \
  libxapian30 \
  libmariadb3 \
  libpq5 \
  libexpat1 \
  libsqlite3-0 \
  libicu76 \
  libcap2 \
  libcap2-bin \
  libsasl2-2 \
  libsasl2-modules \
  netcat-traditional \
  ca-certificates && \
 rm -rf /etc/dovecot && \
 rm -rf /var/lib/apt/lists && \
 groupadd -g $VMAIL_GID vmail && \
 useradd -u $VMAIL_UID -g vmail -G ssl-cert -d /srv/mail -s /bin/sh vmail && \
 passwd -l vmail && \
 mkdir -p /run && \
 chmod 1777 /run && \
 mkdir /etc/dovecot && \
 mkdir /etc/dovecot/vendor.d && \
 mkdir /etc/dovecot/conf.d && \
 mkdir /etc/dovecot/ssl && \
 mkdir /srv/vmail -p && \
 mkdir /var/lib/dovecot

COPY auth.conf /etc/dovecot/conf.d/auth.conf
COPY ssl.conf /etc/dovecot/conf.d/ssl.conf

FROM production-base AS production-root

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"
ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC \
    PATH=$PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

RUN groupadd --system dovecot && \
 groupadd --system dovenull && \
 useradd -g dovecot --system dovecot && \
 useradd -g dovenull --system dovenull && \
 make-ssl-cert generate-default-snakeoil && \
 ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/ssl/tls.crt && \
 ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/ssl/tls.key && \
 chown root:dovecot /etc/dovecot/ssl/tls.key && \
 chmod 0440 /etc/dovecot/ssl/tls.key

COPY dovecot.conf /etc/dovecot/dovecot.conf

EXPOSE 24
EXPOSE 110
EXPOSE 143
EXPOSE 587
EXPOSE 993
EXPOSE 995
EXPOSE 190
EXPOSE 8080
EXPOSE 9090

USER root
VOLUME ["/srv/mail"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/dovecot/sbin/dovecot", "-F"]

FROM production-base AS production-dev

USER root

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"
ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC \
    PATH=/bin/sbin:/usr/bin:/usr/sbin:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

RUN chown vmail:vmail /var/lib/dovecot && \
 chown vmail:vmail /srv/vmail && \
 chmod 0770 /var/lib/dovecot && \
 chmod 0700 /srv/vmail && \
 make-ssl-cert generate-default-snakeoil && \
 ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/ssl/tls.crt && \
 ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/ssl/tls.key && \
 chown root:vmail /etc/dovecot/ssl/tls.key && \
 chmod 0440 /etc/dovecot/ssl/tls.key && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/script-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/imap-urlauth-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/submission-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/managesieve-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/pop3-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/imap-login && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/lmtp && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/anvil && \
 setcap cap_sys_chroot+ep /dovecot/libexec/dovecot/managesieve-login

COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY rootless.conf /etc/dovecot/vendor.d/rootless.conf

EXPOSE 31024
EXPOSE 31110
EXPOSE 31143
EXPOSE 31587
EXPOSE 31993
EXPOSE 31995
EXPOSE 34190
EXPOSE 8080
EXPOSE 9090
USER vmail
VOLUME ["/srv/mail"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/dovecot/sbin/dovecot", "-F"]

FROM production-dev AS production

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"

ENV container=docker \
    LC_ALL=C.UTF-8 TZ=UTC \
    PATH=$PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apt remove --allow-remove-essential -yq \
  bash \
  pkg-config \
  util-linux \
  procps \
  sensible-utils \
  perl-base \
  ncurses-bin \
  gzip \
  sed \
  libcap2-bin && \
 ln -srf /bin/true /usr/share/debconf/frontend && \
 dpkg --remove --ignore-depends=dpkg --ignore-depends=base-files --force-remove-essential tar mawk && \
 ln -srf /bin/true /bin/tar && \
 dpkg --remove --force-remove-essential --force-depends apt sqv dpkg diffutils findutils init-system-helpers sysvinit-utils coreutils mount grep debian-utils libc-bin

EXPOSE 31024
EXPOSE 31110
EXPOSE 31143
EXPOSE 31587
EXPOSE 31993
EXPOSE 31995
EXPOSE 34190
EXPOSE 8080
EXPOSE 9090
USER vmail
VOLUME ["/srv/mail"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/dovecot/sbin/dovecot", "-F"]
