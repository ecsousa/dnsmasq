# syntax=docker/dockerfile:1

FROM alpine:edge AS builder

RUN apk add --no-cache \
    build-base \
    libidn2-dev \
    nettle-dev \
    dbus-dev \
    gettext \
    curl \
    linux-headers

WORKDIR /src

RUN curl -L https://thekelleys.org.uk/dnsmasq/dnsmasq-2.92.tar.gz -o dnsmasq.tar.gz && \
    tar -xzf dnsmasq.tar.gz --strip-components=1 && \
    make COPTS="-DHAVE_DNSSEC -DHAVE_LIBIDN2 -DHAVE_DBUS"

FROM alpine:edge

RUN set -eu && \
    apk --no-cache add \
    tini \
    bash \
    libidn2 \
    nettle \
    dbus-libs && \
    mkdir -p /etc/default/ && \
    echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /etc/default/dnsmasq && \
    rm -f /etc/dnsmasq.conf && \
    rm -rf /tmp/* /var/cache/apk/*

COPY --from=builder /src/src/dnsmasq /usr/sbin/dnsmasq
COPY --chmod=755 entry.sh /usr/bin/dnsmasq.sh
COPY --chmod=664 dnsmasq.conf /etc/dnsmasq.default

ENV DNS1="1.0.0.1"
ENV DNS2="1.1.1.1"
ENV FILTER_AAAA=""

EXPOSE 53/tcp 53/udp 67/udp

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/dnsmasq.sh"]
