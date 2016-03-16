FROM alpine:3.3

ENV CONFIG_SOURCE="" \
    GOROOT=/usr/lib/go \
    GOPATH=/gopath \
    GOBIN=/usr/bin

ADD sync-config.sh /usr/bin/sync-config

RUN apk add -U --no-cache go git gnupg && \
    go get -v github.com/ncw/rclone && \
    adduser -D orbit && \
    apk del --purge go git && \
    rm -rf /var/cache/apk && \
    rm -rf /gopath && \
    mkdir /home/orbit/config && \
    chmod +x /usr/bin/sync-config

USER orbit

WORKDIR /home/orbit/

VOLUME /home/orbit/config

CMD ["/usr/bin/sync-config"]
