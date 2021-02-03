FROM alpine:3.13.1 as base_stage

LABEL maintainer="beardedeagle <randy@heroictek.com>"

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images.
ENV REFRESHED_AT=2021-02-02 \
  OTP_VER=23.2.3 \
  REBAR3_VER=3.14.3 \
  TERM=xterm \
  LANG=C.UTF-8

RUN set -xe \
  && apk --no-cache update \
  && apk --no-cache upgrade \
  && apk add --no-cache \
    bash \
    git \
    openssl \
    zlib \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

FROM base_stage as deps_stage

RUN set -xe \
  && apk add --no-cache --virtual .build-deps \
    autoconf \
    curl \
    dpkg \
    dpkg-dev \
    g++ \
    gcc \
    make \
    musl-dev \
    ncurses-dev \
    openssl-dev \
    rsync \
    sed \
    tar \
    unzip \
    zlib-dev

FROM deps_stage as erlang_stage

RUN set -xe \
  && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VER}.tar.gz" \
  && OTP_DOWNLOAD_SHA256="3160912856ba734bd9c17075e72f469b9d4b913f3ab9652ee7e0fb406f0f0f2c" \
  && curl -fSL -o otp-src.tar.gz "${OTP_DOWNLOAD_URL}" \
  && echo "${OTP_DOWNLOAD_SHA256}  otp-src.tar.gz" | sha256sum -c - \
  && export ERL_TOP="/usr/src/otp_src_${OTP_VER%%@*}" \
  && mkdir -vp "${ERL_TOP}" \
  && tar -xzf otp-src.tar.gz -C "${ERL_TOP}" --strip-components=1 \
  && rm otp-src.tar.gz \
  && ( cd "${ERL_TOP}" \
    && ./otp_build autoconf \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure --build="${gnuArch}" \
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
      --without-odbc \
      --disable-hipe \
      --enable-m64-build \
      --enable-threads \
      --enable-shared-zlib \
      --enable-ssl=dynamic-ssl-lib \
      --enable-kernel-poll \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install ) \
  && rm -rf "${ERL_TOP}" \
  && find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
  && find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true \
  && find /usr/local -name src | xargs -r find | xargs rmdir -vp || true \
  && scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
  && scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded

FROM erlang_stage as rebar3_stage

RUN set -xe \
  && REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VER}.tar.gz" \
  && REBAR3_DOWNLOAD_SHA256="69024b30f17b52c61e5e0568cbf9a2db325eb646ae230c48858401507394f5c0" \
  && curl -fSL -o rebar3-src.tar.gz "${REBAR3_DOWNLOAD_URL}" \
  && echo "${REBAR3_DOWNLOAD_SHA256}  rebar3-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/rebar3-src \
  && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
  && rm -f rebar3-src.tar.gz \
  && cd /usr/src/rebar3-src \
  && HOME="${PWD}" ./bootstrap \
  && install -v ./rebar3 /usr/local/bin/

FROM deps_stage as stage

COPY --from=rebar3_stage /usr/local /opt/rebar3

RUN set -xe \
  && rsync -a /opt/rebar3/ /usr/local \
  && apk del .build-deps \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

FROM base_stage

COPY --from=stage /usr/local /usr/local
