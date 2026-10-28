#!/bin/bash
set -e

WP_PATH="/var/www/html"

echo "[INFO] Entering working directory $WP_PATH"
cd $WP_PATH

db_password=$(cat /run/secrets/db_password.txt)

echo "[INFO] Waiting for MariaDB to wake up..."
until mysqladmin ping -h mariadb -u "wp_user" -p"$db_password" --silent; do
  echo "Still waiting for database..."
  sleep 1
done
echo "[INFO] MariaDB is ready, continuing!"

if [ -f "$CONTROL_FILE/wp-config.php" ]; then
    echo "[INFO] WordPress is already installed. Skipping installation."
else
    echo "[INFO] Starting clean WordPress installation..."

    echo "[INFO] Downloading WordPress core..."
    wp core download --allow-root --force

    echo "[INFO] Creating wp-config.php configuration file..."
    wp config create --dbname="wordpress_db" --dbpass="$db_password" --dbuser="wp_user" --dbhost="mariadb" --allow-root --force

    CREDENTIALS="/run/secrets/credentials.txt"
    if [ -f "$CREDENTIALS" ]; then
        echo "[INFO] Loading users from the secrets file..."
        ADMIN_COl=$(sed -n '1p' "$CREDENTIALS")
        IFS=":" read -r ADMIN_USER ADMIN_PASS <<< "$ADMIN_COl"

        USER_COL=$(sed -n '2p' "$CREDENTIALS")
        IFS=":" read -r USER PASS <<< "$USER_COL"

        ADMIN_MAIL=$(sed -n '3p' "$CREDENTIALS" | cut -d':' -f2)
        USER_MAIL=$(sed -n '4p' "$CREDENTIALS" | cut -d':' -f2)
    else
        echo "[ERROR] Credentials file does not exist!"
        exit 1
    fi

    echo "[INFO] Running core install (creating administrator: $ADMIN_USER)..."
    wp core install --title="vokotera_web" --url="vokotera.42.fr" --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASS" --admin_email="$ADMIN_MAIL" --allow-root

    echo "[INFO] Creating regular user: $USER..."
    wp user create "$USER" "$USER_MAIL" --user_pass="$PASS" --role='author' --allow-root

    echo "[SUCCESS] WordPress has been successfully installed!"

fi
echo "[INFO] Starting PHP-FPM in the foreground (PID 1)..."
exec php-fpm8.2 -F