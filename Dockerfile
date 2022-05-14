FROM alpine:3.15 AS builder

ARG RECORDER_VERSION=0.8.8
# ARG RECORDER_VERSION=master

RUN apk add \
        make \
        gcc \
        git \
        shadow \
        musl-dev \
        curl-dev \
        libconfig-dev \
        mosquitto-dev \
        lmdb-dev \
        libsodium-dev \
        lua5.2-dev

RUN git clone --branch=${RECORDER_VERSION} https://github.com/owntracks/recorder
WORKDIR recorder

COPY config.mk .
RUN make -j $(nprocs)
RUN make install DESTDIR=/app

FROM alpine:3.15

VOLUME ["/store", "/config"]

RUN apk add \
	curl \
    jq \
    libcurl \
    libconfig \
    mosquitto \
    lmdb \
    libsodium \
    lua5.2

COPY recorder.conf /config/recorder.conf
COPY JSON.lua /config/JSON.lua
COPY --from=builder /app /

COPY recorder-health.sh /usr/local/sbin/recorder-health.sh

# If you absolutely need health-checking, enable the option below.  Keep in
# mind that until https://github.com/systemd/systemd/issues/6432 is resolved,
# using the HEALTHCHECK feature will cause systemd to generate a significant
# amount of spam in the system logs.
# HEALTHCHECK CMD /usr/local/sbin/recorder-health.sh

EXPOSE 8083

ENTRYPOINT ["/usr/sbin/ot-recorder"]
