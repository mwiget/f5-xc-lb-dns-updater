FROM alpine:3.15.4
RUN apk add --no-cache curl jq
RUN curl -o /usr/bin/vesctl.gz https://vesio.azureedge.net/releases/vesctl/0.2.28/vesctl.linux-amd64.gz \
  && gzip -d /usr/bin/vesctl.gz \
  && chmod a+rx /usr/bin/vesctl

COPY api-creds.json pwd.json entrypoint.sh /root/
RUN chmod a+rx /root/entrypoint.sh

ENTRYPOINT ["/bin/sh","/root/entrypoint.sh"]
