#!/bin/bash
set -e

WP_PATH="/var/www/html"

echo "[INFO] Entering working directory $WP_PATH"
cd "$WP_PATH"

db_password=$(cat /run/secrets/db_password.txt)
admin_password=$(cat /run/secrets/wp_admin_password.txt)
user_password=$(cat /run/secrets/wp_user_password.txt)

echo "[INFO] Waiting for MariaDB to wake up..."
until mysqladmin ping -h mariadb -u "$MYSQL_USER" -p"$db_password" --silent; do
  echo "Still waiting for database..."
  sleep 1
done
echo "[INFO] MariaDB is ready, continuing!"

if [ -f "$WP_PATH/wp-config.php" ]; then
    echo "[INFO] WordPress is already installed. Skipping installation."
else
    echo "[INFO] Starting clean WordPress installation..."

    echo "[INFO] Downloading WordPress core..."
    wp core download --allow-root --force

    echo "[INFO] Creating wp-config.php configuration file..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$db_password" \
        --dbhost="mariadb" \
        --allow-root \
        --force

    echo "[INFO] Running core install (creating administrator: $WP_ADMIN_USER)..."
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$admin_password" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    echo "[INFO] Creating regular user: $WP_USER..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$user_password" \
        --role='author' \
        --allow-root

    echo "[SUCCESS] WordPress has been successfully installed!"

fi
echo "[INFO] Starting PHP-FPM in the foreground (PID 1)..."
exec php-fpm8.2 -F