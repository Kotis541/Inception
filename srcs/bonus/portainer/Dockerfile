FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/portainer.tar.gz https://github.com/portainer/portainer/releases/download/2.21.3/portainer-2.21.3-linux-amd64.tar.gz \
    && tar -xzf /tmp/portainer.tar.gz -C /opt/ \
    && rm -f /tmp/portainer.tar.gz

WORKDIR /opt/portainer

RUN mkdir -p /data/portainer

CMD ["/opt/portainer/portainer", "--data=/data/portainer"]