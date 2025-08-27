FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates bash procps jq \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/maidsafe/safeup/main/install.sh | bash

ENV WALLET_ADDRESS= \
    NODE_COUNT=1 \
    DATA_DIR=/data \
    PORT_START=61000

RUN useradd -m -u 1000 autonomi && mkdir -p /data && chown -R autonomi:autonomi /data
USER autonomi
WORKDIR /home/autonomi

COPY --chown=autonomi:autonomi entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
