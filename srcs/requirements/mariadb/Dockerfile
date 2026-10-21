FROM debian:bookworm

COPY conf/mariadb.cnf /etc/mysql/conf.d/custom.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN apt-get update
RUN apt-get install -y mariadb-server
RUN chmod +x /usrc/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]