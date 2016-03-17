FROM alpine:3.3

ENV CONFIG_SOURCE="" \
    GOROOT=/usr/lib/go \
    GOPATH=/gopath \
    GOBIN=/usr/bin

RUN apk add -U --no-cache go git gnupg && \
    go get -v github.com/ncw/rclone && \
    adduser -D orbit && \
    apk del --purge bash go git && \
    rm -rf /var/cache/apk && \
    rm -rf /gopath && \
    mkdir /config

WORKDIR /home/orbit/

VOLUME /config

COPY sync-config.sh /usr/bin/sync-config
COPY rclone.conf /home/orbit/.rclone.conf

CMD ["/usr/bin/sync-config"]
