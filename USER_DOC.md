# User & Administrator Documentation (Inception)

Welcome to the **Inception** project user guide. This document provides clear, step-by-step instructions for operating, managing, and inspecting the containerized web infrastructure.

---

## 1. Services Provided by the Stack
The infrastructure runs three isolated services that cooperate to serve a dynamic WordPress website:

1. **NGINX (Web Server & Gateway):**
   - The single entry point to the system.
   - Listens on port `443` (HTTPS) with TLS encryption.
   - Handles static assets directly and securely forwards dynamic PHP requests to WordPress.

2. **WordPress (Application Engine):**
   - Runs PHP-FPM in the background to execute WordPress PHP scripts.
   - Generates the dynamic web pages and processes administration task

3. **MariaDB (Database Backend):**
   - Dedicated relational database server.
   - Stores website content, articles, site configuration, and user profiles.

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

---

## 4. Locating and Managing Credentials
Sensitive passwords and user logins are never stored in public code or environment files. Instead, they reside in the root `secrets/` directory:
```text
secrets/
├── credentials.txt          # WordPress administrator and regular user logins
├── db_password.txt          # Password for WordPress database user
└── db_root_password.txt     # Root password for MariaDB administration
```

### Default Accounts
Open `secrets/credentials.txt` to find:
- **Administrator Account:** Has full rights over the WordPress site, plugins, and settings.
- **Regular User Account:** Author-level user for publishing and editing posts.

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
```

### Health Check via Terminal (HTTP / HTTPS)
You can quickly test connectivity directly from your command line:
```bash
# Verify that HTTPS returns HTTP 200 OK
curl -kI https://vokotera.42.fr
# Verify that insecure HTTP (port 80) is completely blocked / refused
curl -I http://vokotera.42.fr
```