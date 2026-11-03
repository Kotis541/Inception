#!/bin/sh
set -e

DATA_DIR="/var/lib/mysql"
CONTROL_FILE="$DATA_DIR/mysql"

echo "--- Checking for a previous database installation ---"

if [ -d "$CONTROL_FILE" ]; then
    echo "[INFO] System file "$CONTROL_FILE" was found."
    echo "[INFO] Database was alredy made"
else
    echo "[WARN] System file "$CONTROL_FILE" was not found."
    echo "[INFO] Starting first initialization of the database.."


    if [ -f "/run/secrets/db_password.txt" ]; then
        db_password=$(cat /run/secrets/db_password.txt)
    else
        echo "[ERROR] Initialization failed: File with credentials doesn't exist!"
        exit 1
    fi

    if [ -f "/run/secrets/db_root_password.txt" ]; then
        db_root_password=$(cat /run/secrets/db_root_password.txt)
    else
        echo "[ERROR] Initialization failed: root password for database doesn't exist!"
        exit 1
    fi

    echo "[INFO] Generates system tables Mariadb"
    mariadb-install-db --user=mysql --datadir="$DATA_DIR"

    mysqld --user=mysql --datadir="$DATA_DIR" &

    while ! mysqladmin ping --silent; do
        sleep 1
    done

    cat << EOF > /tmp/init.sql
    CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
    CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$db_password';
    GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '$db_root_password';
    FLUSH PRIVILEGES;
EOF
    mariadb -u root < /tmp/init.sql

    mysqladmin -u root -p"$db_root_password" shutdown

    echo "[OK] Initialization of MariaDB was success!"
fi

    echo "[INFO] Starting main MariaDB process..."
    exec mysqld --user=mysql


