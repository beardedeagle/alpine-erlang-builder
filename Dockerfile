FROM alpine:3.12.0 as base_stage

LABEL maintainer="beardedeagle <randy@heroictek.com>"

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images.
ENV REFRESHED_AT=2020-07-16 \
  OTP_VER=23.0.2 \
  REBAR3_VER=3.13.2 \
  TERM=xterm \
  LANG=C.UTF-8

RUN set -xe \
  && apk --update --no-cache upgrade \
  && apk add --no-cache \
    bash \
    openssl \
    lksctp-tools \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/*

FROM base_stage as deps_stage

RUN set -xe \
  && apk add --no-cache --virtual .build-deps \
    autoconf \
    bash-dev \
    binutils-gold \
    ca-certificates \
    curl curl-dev \
    dpkg dpkg-dev \
    g++ \
    gcc \
    libc-dev \
    openssl-dev \
    linux-headers \
    lksctp-tools-dev \
    make \
    musl musl-dev \
    ncurses ncurses-dev \
    rsync \
    tar \
    unixodbc unixodbc-dev \
    zlib zlib-dev \
  && update-ca-certificates --fresh

FROM deps_stage as erlang_stage

RUN set -xe \
  && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VER}.tar.gz" \
  && OTP_DOWNLOAD_SHA256="6bab92d1a1b20cc319cd845c23db3611cc99f8c99a610d117578262e3c108af3" \
  && curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
  && echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
  && export ERL_TOP="/usr/src/otp_src_${OTP_VER%%@*}" \
  && mkdir -vp $ERL_TOP \
  && tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
  && rm otp-src.tar.gz \
  && ( cd $ERL_TOP \
    && ./otp_build autoconf \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure --build="$gnuArch" \
      --without-javac \
      --without-wx \
      --without-debugger \
      --without-observer \
      --without-jinterface \
      --without-cosEvent\
      --without-cosEventDomain \
      --without-cosFileTransfer \
      --without-cosNotification \
      --without-cosProperty \
      --without-cosTime \
      --without-cosTransactions \
      --without-et \
      --without-gs \
      --without-ic \
      --without-megaco \
      --without-orber \
      --without-percept \
      --without-typer \
      --enable-threads \
      --enable-shared-zlib \
      --enable-ssl=dynamic-ssl-lib \
      --enable-kernel-poll \
      --enable-hipe \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install ) \
  && rm -rf $ERL_TOP \
  && find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
  && find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true \
  && find /usr/local -name src | xargs -r find | xargs rmdir -vp || true \
  && scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
  && scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded

FROM erlang_stage as rebar3_stage

RUN set -xe \
  && REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VER}.tar.gz" \
  && REBAR3_DOWNLOAD_SHA256="e14cdc1f5b7d363a238a9f555f89e878bc4fc836c970571b41b90ee947f91505" \
  && curl -fSL -o rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
  && echo "$REBAR3_DOWNLOAD_SHA256  rebar3-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/rebar3-src \
  && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
  && rm rebar3-src.tar.gz \
  && cd /usr/src/rebar3-src \
  && HOME=$PWD ./bootstrap \
  && install -v ./rebar3 /usr/local/bin/

FROM deps_stage as stage

COPY --from=rebar3_stage /usr/local /opt/rebar3

RUN set -xe \
  && rsync -a /opt/rebar3/ /usr/local \
  && apk del .build-deps \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/*

FROM base_stage

COPY --from=stage /usr/local /usr/local
