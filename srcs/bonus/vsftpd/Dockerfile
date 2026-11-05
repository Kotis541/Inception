FROM debian:bookworm

RUN apt update && \
    apt-get install -y --no-install-recommends vsftpd

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh
RUN mkdir -p /var/run/vsftpd/empty

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
