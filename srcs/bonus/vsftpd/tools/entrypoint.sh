#!/bin/sh
set -e

SECRET_FILE="/run/secrets/ftp_pass.txt"

if [ -z "$FTP_USER" ]; then
    echo "[ERROR] Variable FTP_USER is not setup!"
    exit 1
fi

if [ ! -f "$SECRET_FILE" ]; then
    echo "[ERROR] Password for FTP doesn't exists!"
    exit 1
fi

FTP_PASS=$(cat "$SECRET_FILE")

if ! id "$FTP_USER" &>/dev/null; then
    echo "[INFO] Making new user '$FTP_USER'.."

    useradd -d /var/www/html -s /bin/sh "$FTP_USER"

    echo "$FTP_USER:$FTP_PASS" | chpasswd

    echo "User '$FTP_USER' was succesfully made!"

else
    echo "User '$FTP_USER' already exists!"
fi

unset FTP_PASS
chmod -R 777 /var/www/html
exec /usr/sbin/vsftpd /etc/vsftpd.conf