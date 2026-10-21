#!/bin/sh
set -e

DATA_DIR="/var/lib/mysql"
CONTROL_FILE="$DATA_DIR/mysql"

echo "--- Checking for a previous database installation ---"

if [ -d "$CONTROL_FILE" ]; then
    echo "[INFO] System file "$CONTROL_FILE" was find out."
    echo "[INFO] Database was alredy made"
else
    echo "[WARN] System file "$CONTROL_FILE" wasn't find out"
    echo "[INFO] Starting first initialization of the database"


    if [ -f "/secrets/db_password" ]; then
        db_password=$( cat secrets/db_password.txt )
    else
        echo "[ERROR] Initalization failed: File with credentials don't exists!"
        exit 1

    if [ -f "secrets/db_root_password.txt" ]; then
        db_root_password=$( cat secrets/db_root_password.txt )
    else
        echo "[ERROR] Initialization failed: root password for database don't exists!"
        exit 1
    fi

    echo "[INFO] Generates system tables Mariadb"
    mariadb-install-db 

    echo "[OK] Initialization of MariaDB was success!"

fi
echo "[INFO] Starting main MariaDB process..."
