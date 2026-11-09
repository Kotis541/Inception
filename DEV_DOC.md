# Developer Documentation (Inception)

This documentation is intended for developers contributing to or maintaining the **Inception** infrastructure. It outlines environment setup from scratch, configuration architectures, build lifecycle, developer operations, and data persistence models.

---

## Table of Contents
1. [Environment Setup from Scratch](#1-environment-setup-from-scratch)
   - [Prerequisites](#prerequisites)
   - [Host Resolution](#host-resolution)
   - [Configuration Files (.env)](#configuration-files-env)
   - [Secrets Setup](#secrets-setup)
2. [Building and Launching the Project](#2-building-and-launching-the-project)
   - [Using GNU Make](#using-gnu-make)
   - [Using Docker Compose Directly](#using-docker-compose-directly)
3. [Container and Volume Management](#3-container-and-volume-management)
   - [Inspecting System Health & Logs](#inspecting-system-health--logs)
   - [Interactive Debugging Inside Containers](#interactive-debugging-inside-containers)
   - [Direct Database & WP-CLI Operations](#direct-database--wp-cli-operations)
   - [Network and Volume Inspection](#network-and-volume-inspection)
4. [Data Storage & Persistence Architecture](#4-data-storage--persistence-architecture)
   - [Storage Locations](#storage-locations)
   - [Persistence Model](#persistence-model)
   - [Lifecycle and Clean Up](#lifecycle-and-clean-up)

---

## 1. Environment Setup from Scratch

### Prerequisites
Ensure the host development system meets the following requirements:
- **Operating System:** Linux (Debian 12 / Ubuntu 22.04+ recommended) or Linux VM.
- **Docker Engine:** Version 24.0+
- **Docker Compose:** Plugin V2 (version 2.20+)
- **Build Utilities:** `make`, `curl`, `openssl`

### Host Resolution
The web server routes traffic based on the designated domain name `vokotera.42.fr`. Add the local loopback entry to `/etc/hosts` on the host operating system:
```bash
nano /etc/hosts 
```
and then add
 ```bash
127.0.0.1 vokotera.42.fr
```

Verify resolution:
```bash
ping -c 2 vokotera.42.fr
```

### Configuration Files (.env)

Create the environment file at `srcs/.env` with non-sensitive deployment parameters:
```env
DOMAIN_NAME=vokotera.42.fr

# MariaDB Settings
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user

# WordPress Administration
WP_TITLE=vokotera_web
WP_ADMIN_USER=vokotera
WP_ADMIN_EMAIL=vokotera@student.42prague.com

# WordPress Regular User
WP_USER=besthustler
WP_USER_EMAIL=votera@seznam.cz

# FTP Server (Bonus)
FTP_CONTAINER=ftp_server
FTP_USER=kotis
FTP_DATA_PATH=/var/www/html
```

### Secrets Setup
Sensitive credentials must reside in individual text files inside the `secrets/` directory at the project root. Create them with strict permissions (do not commit them to Git):
```bash
mkdir -p secrets
echo -n "MySuperSecureDbPassword123" > secrets/db_password.txt
echo -n "MySuperSecureDbRootPassword123" > secrets/db_root_password.txt
echo -n "MySuperSecureWpAdminPass123" > secrets/wp_admin_password.txt
echo -n "MySuperSecureWpUserPass123" > secrets/wp_user_password.txt
echo -n "MySuperSecureFtpPassword123" > secrets/ftp_pass.txt
chmod 600 secrets/*.txt
```

---

## 2. Building and Launching the Project

### Using GNU Make
The root [Makefile](Makefile) orchestrates the build process, directory preparation, and container lifecycle.

| Target | Description | Command |
|---|---|---|
| `all` / `up` | Creates host storage directories, builds images, and starts containers in detached mode | `make` or `make up` |
| `down` | Stops and removes containers and internal networks (preserves data volumes) | `make down` |
| `clean` | Alias for `down` | `make clean` |
| `fclean` | Deep purge: stops containers, destroys volumes, removes images, and wipes host data directories | `make fclean` |
| `re` | Executes `fclean` followed by `all` to rebuild completely from scratch | `make re` |


### Using Docker Compose Directly
If you need direct compose execution without `make`, target the configuration file explicitly:
```bash
# Build and start in detached mode
docker compose -f srcs/docker-compose.yml up --build -d
# Verify syntax and variable interpolation
docker compose -f srcs/docker-compose.yml config
# Stop all services
docker compose -f srcs/docker-compose.yml down
```

---

## 3. Container and Volume Management

### Inspecting System Health & Logs
```bash
# View active containers and port exposures
docker ps

# Follow aggregated logs across all services
docker compose -f srcs/docker-compose.yml logs -f

# Follow specific service logs
docker logs -f wordpress
docker logs -f mariadb
```

### Interactive Debugging Inside Containers
To open an interactive shell inside any container:
```bash
# Open bash in WordPress container
docker exec -it wordpress bash

# Open shell in MariaDB container
docker exec -it mariadb sh

# Test internal NGINX configuration
docker exec -it nginx nginx -t
```

### Direct Database & WP-CLI Operations
Developers can interact directly with the database or WordPress engine without entering the containers:
- **Query MariaDB:**
  ```bash
  docker exec -i mariadb mariadb -u root -p"$(cat secrets/db_root_password.txt)" wordpress_db -e "SHOW TABLES;"
  ```
- **Execute WP-CLI commands:**
  ```bash
  # Check WordPress installation status
  docker exec -it wordpress wp core is-installed --allow-root

  # List existing WordPress users
  docker exec -it wordpress wp user list --allow-root

  # Interactive sql with your own commands
  docker exec -it mariadb mariadb -u root -p"$(cat secrets/db_root_password.txt)" wordpress_db
  ```

- **Redis Cache Operations:**
  ```bash
  # Test Redis responsiveness (returns PONG)
  docker exec -it redis redis-cli ping

  # Live-monitor Redis cache operations (GET/SET) in real time
  docker exec -it redis redis-cli monitor

  # Check Redis object cache status from WordPress
  docker exec -it wordpress wp redis status --allow-root
  ```

- **FTP Server Operations (vsftpd):**
  ```bash
  # List files through FTP
  curl -u kotis:$(cat secrets/ftp_pass.txt) ftp://127.0.0.1/

  # Upload a test file to WordPress files directory
  curl -T /tmp/test.txt -u kotis:$(cat secrets/ftp_pass.txt) ftp://127.0.0.1/test.txt

  # Delete test file remotely via FTP
  curl -u kotis:$(cat secrets/ftp_pass.txt) ftp://127.0.0.1/ -Q "DELE test.txt"
  ```

- **Static Website Operations:**
  ```bash
  # Inspect static website files inside container
  docker exec -it website ls -la /var/www/website

  # Verify NGINX reverse-proxy response for static website
  curl -kI https://vokotera.42.fr/website/
  ```

- **Adminer Database Manager Operations:**
  ```bash
  # Verify Adminer PHP-FPM process configuration
  docker exec -it adminer php-fpm8.2 -t

  # Verify NGINX reverse-proxy response for Adminer
  curl -kI https://vokotera.42.fr/adminer
  ```

- **Portainer Container Dashboard Operations:**
  ```bash
  # Check Portainer process status and PID 1 execution
  docker exec -it portainer ps aux

  # Verify Docker daemon communication via socket inside Portainer
  docker exec -it portainer ls -l /var/run/docker.sock

  # Verify Portainer web interface endpoint
  curl -kI https://vokotera.42.fr/portainer/
  ```

### Network and Volume Inspection
```bash
# Inspect custom bridge network
docker network inspect srcs_inception

# Inspect named volume mounts
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_portainer_data
```

---

## 4. Data Storage & Persistence Architecture

### Storage Locations
In accordance with 42 project requirements, persistent data is stored directly on the host filesystem under `/home/vokotera/data`:

| Service | Container Mount Point | Host Storage Path | Driver Configuration |
|---|---|---|---|
| **MariaDB** | `/var/lib/mysql` | `/home/vokotera/data/mariadb` | Local bind mount (`type: none`, `o: bind`) |
| **WordPress** | `/var/www/html` | `/home/vokotera/data/wordpress` | Local bind mount (`type: none`, `o: bind`) |
| **NGINX** | `/var/www/html:ro` | `/home/vokotera/data/wordpress` | Read-only shared mount |
| **vsftpd** | `/var/www/html` | `/home/vokotera/data/wordpress` | Read/write shared mount |
| **Portainer** | `/data/portainer` | `/home/vokotera/data/portainer` | Local bind mount (`type: none`, `o: bind`) |

### Persistence Model
1. **Named Volumes with Host Bind:**  
   Docker manages `mariadb_data`, `wordpress_data`, and `portainer_data` as named volumes, but delegates the underlying storage directly to host directory bind points via `driver_opts`.
2. **Crash & Restart Resilience:**  
   When containers are stopped or recreated (`make down` followed by `make up`), the files remain intact on the host. The entrypoint scripts check for existing database files (`/var/lib/mysql/mysql`) and WordPress configs (`/var/www/html/wp-config.php`), bypassing fresh installation if valid data already exists.
3. **Redis In-Memory Ephemeral Storage:**  
   Redis operates purely in-memory as a high-speed volatile cache. It intentionally does not mount a persistent host volume because all cached database query objects are ephemeral and can be safely re-generated on demand from MariaDB upon container recreation or cache misses.
4. **Portainer Persistence & Docker Socket Integration:**  
   Portainer stores its internal configuration, user databases (`portainer.db`), and dashboard settings persistently in `/home/vokotera/data/portainer`. To interact with and manage the host's Docker engine without running privileged daemons, Portainer mounts the host's Docker UNIX socket (`/var/run/docker.sock`).
5. **Stateless Bonus Services (Adminer & Website):**  
   The static website and Adminer services are completely stateless. Their application code and static HTML/CSS files are baked directly into their respective container images during `docker compose build`, requiring no external storage volumes.

### Lifecycle and Clean Up
- **Preserved State:** `make down` keeps `/home/vokotera/data` completely intact.
- **Complete Purge:** `make fclean` executes a privileged helper container (`debian:bookworm`) to safely wipe the root-owned files inside `/home/vokotera/data/mariadb`, `/home/vokotera/data/wordpress`, and `/home/vokotera/data/portainer` without prompting the developer for `sudo` passwords.