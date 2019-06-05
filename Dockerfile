FROM balenalib/armv7hf-alpine:latest-run

ENV SS_VER 3.2.5
ENV SS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/v$SS_VER.tar.gz
ENV SS_DIR shadowsocks-libev-$SS_VER
ENV V2RAY_VER 1.1.0

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
    curl \
    tar \
    && curl -sSL $SS_URL | tar xz \
    # Build & install
    && cd $SS_DIR \
    && curl -sSL https://github.com/shadowsocks/ipset/archive/shadowsocks.tar.gz | tar xz --strip 1 -C libipset \
    && curl -sSL https://github.com/shadowsocks/libcork/archive/shadowsocks.tar.gz | tar xz --strip 1 -C libcork \
    && curl -sSL https://github.com/shadowsocks/libbloom/archive/master.tar.gz | tar xz --strip 1 -C libbloom \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install \
    && cd .. \
    && rm -rf $SS_DIR \
    && apk del .build-deps \
    # Runtime dependencies setup
    && apk add --no-cache --update \
    rng-tools \
    ca-certificates \
    $(scanelf --needed --nobanner /usr/bin/ss-* \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u) \
    && rm -rf /tmp/repo \
    && curl -sSL https://github.com/shadowsocks/v2ray-plugin/releases/download/v${V2RAY_VER}/v2ray-plugin-linux-arm-v${V2RAY_VER}.tar.gz | tar xz -C /usr/local/bin/v2ray-plugin_linux_arm7  v2ray-plugin_linux_arm7 \

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


