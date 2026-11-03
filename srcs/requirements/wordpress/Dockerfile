FROM debian:bookworm

RUN apt update && \
    apt-get install -y php-fpm php-mysql php-redis mariadb-client curl ca-certificates && \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mkdir -p /run/php && \
    mv wp-cli.phar /usr/local/bin/wp && \
    rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]