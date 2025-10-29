FROM alpine:3.18

RUN apk add --no-cache dante-server \
    && cp /usr/sbin/danted /usr/local/bin/serve \
    && rm -f /etc/danted.conf

ENV PORT=8080 \
    USER=tyreamon \
    PASS=2099 \
    BIND_IP=0.0.0.0

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
