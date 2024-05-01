FROM debian:bookworm-slim
ARG VERSION

RUN npm install -g pouchdb-server@${VERSION}


# Use iptables masquerade NAT rule
ENV IPTABLES_MASQ=1
ENV MONITOR_DOMAIN=""


ENTRYPOINT ["pouchdb-server"]
