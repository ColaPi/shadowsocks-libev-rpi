FROM balenalib/armv7hf-alpine:latest-run

ENV SS_VER 3.2.5
ENV SS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/v$SS_VER.tar.gz
ENV SS_DIR shadowsocks-libev-$SS_VER

RUN set -ex \
    # Build environment setup
    && apk add --no-cache --virtual .build-deps \
    autoconf \
    automake \
    build-base \
    c-ares-dev \
    libev-dev \
    libtool \
    libsodium-dev \
    linux-headers \
    mbedtls-dev \
    pcre-dev \
    # Build & install
    && cd /tmp/repo \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install \
    && apk del .build-deps \
    # Runtime dependencies setup
    && apk add --no-cache --update \
    rng-tools \
    ca-certificates \
    $(scanelf --needed --nobanner /usr/bin/ss-* \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u) \
    && rm -rf /tmp/repo

USER nobody

CMD exec ss-server \
    -s $SERVER_ADDR \
    -p $SERVER_PORT \
    -k ${PASSWORD:-$(hostname)} \
    -m $METHOD \
    -t $TIMEOUT \
    -d $DNS_ADDRS \
    -u \
    $ARGS


