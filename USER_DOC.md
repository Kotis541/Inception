# User & Administrator Documentation (Inception)

Welcome to the **Inception** project user guide. This document provides clear, step-by-step instructions for operating, managing, and inspecting the containerized web infrastructure.

---

## Table of Contents
- [1. Services Provided by the Stack](#1-services-provided-by-the-stack)
- [2. Starting and Stopping the Project](#2-starting-and-stopping-the-project)
  - [Starting the Infrastructure](#starting-the-infrastructure)
  - [Stopping the Infrastructure](#stopping-the-infrastructure)
  - [Restarting Services](#restarting-services)
  - [Full Clean Reset](#full-clean-reset)
- [3. Accessing the Website and Administration Panel](#3-accessing-the-website-and-administration-panel)
  - [Website Access](#website-access)
  - [WordPress Admin Panel](#wordpress-admin-panel)
  - [Static Website (Bonus)](#static-website-bonus)
  - [Adminer Database Manager (Bonus)](#adminer-database-manager-bonus)
  - [Portainer Container Dashboard (Bonus)](#portainer-container-dashboard-bonus)
- [4. Locating and Managing Credentials](#4-locating-and-managing-credentials)
  - [Default Accounts](#default-accounts)
  - [Updating Credentials](#updating-credentials)
- [5. Checking that Services are Running Correctly](#5-checking-that-services-are-running-correctly)
  - [Check Container Status](#check-container-status)
  - [Inspect Service Logs](#inspect-service-logs)
  - [Check Redis Object Cache](#check-redis-object-cache)
  - [Check FTP Server Access](#check-ftp-server-access)
  - [Health Check via Terminal (HTTP / HTTPS Endpoints)](#health-check-via-terminal-http--https-endpoints)

---

## 1. Services Provided by the Stack
The infrastructure runs isolated services that cooperate to serve a dynamic WordPress website:

1. **NGINX (Web Server & Gateway):**
   - The single entry point to the system.
   - Listens on port `443` (HTTPS) with TLS encryption.
   - Handles static assets directly and securely forwards dynamic PHP requests to WordPress.

2. **WordPress (Application Engine):**
   - Runs PHP-FPM in the background to execute WordPress PHP scripts.
   - Generates the dynamic web pages and processes administration tasks.

3. **MariaDB (Database Backend):**
   - Dedicated relational database server.
   - Stores website content, articles, site configuration, and user profiles.

4. **Redis (Object Cache - Bonus):**
   - High-performance in-memory cache running on internal port `6379`.
   - Caches repeated database query results in RAM, significantly accelerating page load times.
   - Operates automatically in the background via the pre-configured `redis-cache` plugin.

5. **FTP Server (vsftpd - Bonus):**
   - File transfer service listening on command port `21` and passive data ports `30000-30100`.
   - Mounted directly to the shared WordPress volume (`/var/www/html`).
   - Enables users and web developers to upload, modify, and download WordPress files using standard FTP clients (FileZilla, WinSCP, curl) without requiring SSH access.

6. **Static Website (Bonus):**
   - Standalone informational web page served through NGINX at `https://vokotera.42.fr/website/`.
   - Demonstrates serving independent static assets alongside dynamic WordPress.

7. **Adminer (Database Management - Bonus):**
   - Single-file database management web interface accessible at `https://vokotera.42.fr/adminer`.
   - Provides an intuitive GUI to inspect, query, and manage MariaDB tables and records.

8. **Portainer (Container Dashboard - Bonus):**
   - Centralized web UI for managing and monitoring all Docker containers, networks, and volumes.
   - Accessible securely via NGINX at `https://vokotera.42.fr/portainer/`.

---

## 2. Starting and Stopping the Project

All container lifecycle tasks are controlled from the root of the repository using the [Makefile](Makefile).

### Starting the Infrastructure
To create the necessary storage directories, build images, and start all containers in detached mode:
```bash
make
# or
make up
```

### Stopping the Infrastructure
To stop all active services without deleting persistent website data or database entries:
```bash
make down
```

### Restarting Services
To apply updates or reboot the entire stack:
```bash
make down
make up
# or
make re
```

### Full Clean Reset
To completely wipe all containers, networks, images, and stored website/database data:
```bash
make fclean
```

---

## 3. Accessing the Website and Administration Panel
Ensure your host machine resolves the domain by verifying that `/etc/hosts` contains:
```text
127.0.0.1 vokotera.42.fr
```
### Website Access
Open your web browser and navigate to:
```text
https://vokotera.42.fr
```
> **Security Notice:** Because the website uses a self-signed SSL certificate, your browser will display a security warning (e.g. *“Your connection is not private”*). Click **Advanced** and select **Proceed to vokotera.42.fr**.

### WordPress Admin Panel
To manage articles, themes, and users, access the administration dashboard at:
```text
https://vokotera.42.fr/wp-admin
```

### Static Website (Bonus)
Access the dedicated static informational page at:
```text
https://vokotera.42.fr/website/
```

### Adminer Database Manager (Bonus)
To inspect and manage MariaDB databases and tables, navigate to:
```text
https://vokotera.42.fr/adminer
```
*Login parameters:*
- **System:** `MySQL` (or `MariaDB`)
- **Server:** `mariadb`
- **Username:** `wp_user` (or `root`)
- **Password:** Password from `secrets/db_password.txt` (or `secrets/db_root_password.txt`)
- **Database:** `wordpress_db`

### Portainer Container Dashboard (Bonus)
To access the centralized Docker management UI, navigate to:
```text
https://vokotera.42.fr/portainer/
```
*(On your first visit, set your administrator username and password, then select the local Docker environment).*

---

## 4. Locating and Managing Credentials
Sensitive passwords and user logins are never stored in public code or environment files. Instead, passwords reside in the root `secrets/` directory, while non-sensitive identities are configured in `srcs/.env`:
```text
secrets/
├── db_password.txt          # Password for WordPress database user
├── db_root_password.txt     # Root password for MariaDB administration
├── ftp_pass.txt             # Password for FTP server user
├── wp_admin_password.txt    # Password for WordPress administrator
└── wp_user_password.txt     # Password for WordPress regular user
```

### Default Accounts
Usernames and emails are defined in `srcs/.env`, and passwords in `secrets/`:
- **Administrator Account:** Configured via `WP_ADMIN_USER` and `wp_admin_password.txt`. Has full rights over the WordPress site, plugins, and settings.
- **Regular User Account:** Configured via `WP_USER` and `wp_user_password.txt`. Author-level user for publishing and editing posts.
- **FTP Account:** Configured via `FTP_USER` in `srcs/.env` and `ftp_pass.txt` in `secrets/`. Accesses the `/var/www/html` root directory.

### Updating Credentials
If you need to change user credentials:
1. Update the appropriate file in the `secrets/` folder.
2. If modifying database passwords or reinitializing users on an existing deployment, perform a reset via `make fclean && make up` so the database and WordPress initialize fresh with the updated credentials.

---

## 5. Checking that Services are Running Correctly
Use the following commands from the root directory to verify system health:

### Check Container Status
Verify that all three containers are in the `Up` state:
```bash
docker ps
```
*Expected output:* You should see `nginx`, `wordpress`, and `mariadb` running with status `Up`.

### Inspect Service Logs
If a service is not behaving as expected, check its live logs:
```bash
# NGINX logs
docker logs -f nginx
# WordPress PHP-FPM & setup logs
docker logs -f wordpress
# MariaDB database logs
docker logs -f mariadb
# Redis cache logs
docker logs -f redis
# FTP server logs
docker logs -f vsftpd
# Static website logs
docker logs -f website
# Adminer logs
docker logs -f adminer
# Portainer logs
docker logs -f portainer
```

### Check Redis Object Cache
Verify that WordPress is actively connected to the Redis cache service:
```bash
docker exec wordpress wp redis status --allow-root
```
*Expected output:* `Status: Connected` and `Dropin: Valid`.

### Check FTP Server Access
Test file listing through FTP from the host terminal:
```bash
curl -u kotis:$(cat secrets/ftp_pass.txt) ftp://127.0.0.1/
```
*Expected output:* Directory listing of WordPress files (`index.php`, `wp-content`, etc.).

### Health Check via Terminal (HTTP / HTTPS Endpoints)
You can quickly test connectivity directly from your command line:
```bash
# Verify WordPress returns HTTP 200 OK
curl -kI https://vokotera.42.fr

# Verify Static Website returns HTTP 200 OK
curl -kI https://vokotera.42.fr/website/

# Verify Adminer returns HTTP 200 OK
curl -kI https://vokotera.42.fr/adminer

# Verify Portainer returns HTTP 200 OK
curl -kI https://vokotera.42.fr/portainer/

# Verify that insecure HTTP (port 80) is completely blocked / refused
curl -I http://vokotera.42.fr
```