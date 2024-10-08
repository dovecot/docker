FROM debian:12-slim as build

ENV container=docker \
    LC_ALL=C
ARG DEBIAN_FRONTEND=noninteractive
ARG DOVECOT_REPO_URL=https://github.com/dovecot
ARG DOVECOT_VERSION=main
ARG PIGEONHOLE_VERSION=main
ARG CC=gcc
ARG EXTRA_CFLAGS="-Wall -Wextra -O2"


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
  libpam0g-dev \
  bison \
  flex \
  libssl-dev \
  libldap2-dev \
  libbz2-dev \
  zlib1g-dev \
  liblzma-dev \
  liblz4-dev \
  libzstd-dev \
  libsystemd-dev \
  libcap-dev \
  libsodium-dev \
  libunwind-dev \
  libwrap0-dev \
  libkrb5-dev \
  libpq-dev \
  libsqlite3-dev \
  libexpat1-dev \
  liblua5.4-dev \
  libclucene-dev \
  libsasl2-dev \
  krb5-multidev \
  libdb-dev \
  libcurl4-gnutls-dev \
  libexpat-dev \
  libexttextcat-dev \
  autotools-dev \
  default-libmysqlclient-dev \
  wget
WORKDIR /root/build/core
RUN  git clone -b $DOVECOT_VERSION $DOVECOT_REPO_URL/core.git .
RUN  ./autogen.sh
RUN  PANDOC=false ./configure \
    --with-ldap=plugin \
    --with-ssl=openssl \
    --with-sql=plugin \
    --with-lua=plugin \
    --with-pgsql \
    --with-mysql \
    --with-sqlite \
    --with-gssapi=plugin \
    --with-solr \
    --with-ioloop=best \
    --with-lucene \
    --with-lz4 \
    --prefix=/dovecot \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --docdir=\${prefix}/share/doc/dovecot-core \
    --with-rundir=/run/dovecot \
    --disable-rpath \
    --disable-static

RUN make -j V=0
RUN make install-strip
WORKDIR /root/build/pigeonhole
RUN git clone -b $PIGEONHOLE_VERSION $DOVECOT_REPO_URL/pigeonhole.git .
RUN ./autogen.sh
RUN ./configure \
    --with-dovecot=/root/build/core \
    --with-ldap=plugin \
    --prefix=/dovecot \
    --sysconfdir=/etc \
    --disable-rpath \
    --disable-static \
    --with-unfinished-features
RUN  make -j V=0
RUN  make install-strip


FROM debian:12-slim as production

LABEL org.opencontainers.image.authors="dovecot@dovecot.org"

ENV container=docker \
    LC_ALL=C
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/dovecot/lib
ENV PATH $PATH:/dovecot/bin:/dovecot/sbin
ARG DEBIAN_FRONTEND=noninteractive

COPY --from=build /dovecot /dovecot
COPY --from=build /dovecot/share/man/man1/* /usr/share/man/man1/
COPY --from=build /dovecot/share/man/man7/* /usr/share/man/man7/
COPY --from=build /dovecot/share/doc/* /usr/share/doc/


RUN apt-get -y update && \
  apt-get -y install --no-install-recommends \
  tini \
  pkg-config \
  ssl-cert \
  ucf \
  libldap-2.5-0 \
  openssl \
  libpam-runtime \
  libpam0g \
  libsodium23 \
  libbz2-1.0 \
  libcrypt1 \
  libexttextcat-2.0-0 \
  liblua5.4-0 \
  liblz4-1 \
  liblzma5 \
  libssl3 \
  libstemmer0d \
  libsystemd0 \
  libtirpc3 \
  libunwind8 \
  libwrap0 \
  libzstd1 \
  zlib1g \
  libgssapi-krb5-2 \
  libkrb5-3 \
  libclucene-core1v5 \
  libmariadb3 \
  libpq5 \
  libexpat1 \
  libsqlite3-0 \
  libcap2 \
  ca-certificates && \
  rm -rf /etc/dovecot && \
  rm -rf /var/lib/apt/lists && \
  mkdir /srv/mail

RUN addgroup --system vmail
RUN adduser --ingroup vmail --disabled-password vmail --home /srv/mail
RUN adduser --disabled-password --no-create-home dovecot
RUN adduser --disabled-password --no-create-home dovenull

RUN chown vmail:vmail /srv/mail && \
  make-ssl-cert generate-default-snakeoil && \
  mkdir /etc/dovecot && \
  ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/cert.pem && \
  ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/key.pem

COPY dovecot.conf /etc/dovecot/dovecot.conf

EXPOSE 24
EXPOSE 110
EXPOSE 143
EXPOSE 587
EXPOSE 990
EXPOSE 993
EXPOSE 4190

VOLUME ["/etc/dovecot", "/srv/mail"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/dovecot/sbin/dovecot", "-F"]
