FROM alpine:latest

ENV RESTIC_VERSION="0.9.0"
ENV RESTIC_TAG="auto"

ADD https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 /

RUN bzip2 -d restic_${RESTIC_VERSION}_linux_amd64.bz2 && \
  mv restic_${RESTIC_VERSION}_linux_amd64 /bin/restic && \
  chmod +x /bin/restic && \
  apk add --no-cache ca-certificates && \
  rm -rf /var/cache/apk/*

COPY profile /etc/profile

COPY entrypoint.sh /entrypoint.sh

COPY backup.sh /bin/backup.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["crond", "-l", "5", "-f" ]

VOLUME ["/backup"]
