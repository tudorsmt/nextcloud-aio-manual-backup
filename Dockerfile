# syntax=docker/dockerfile:latest
FROM alpine:3.20.2

RUN set -ex; \
    \
    apk upgrade --no-cache -a; \
    apk add --no-cache \
        util-linux-misc \
        bash \
        borgbackup \
        rsync \
        fuse \
        py3-llfuse \
        jq

ADD --chmod=744 backup-nextcloud.sh /

ENV BORG_RETENTION_POLICY="--keep-within=7d --keep-weekly=4 --keep-monthly=6"
