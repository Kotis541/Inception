FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl && \
    rm -rf /var/lib/apt/lists/*

COPY conf/ /var/www/html/

EXPOSE 80

CMD [ "nginx", "-g", "daemon off;" ]