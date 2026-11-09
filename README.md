*This project has been created as part of the 42 curriculum by vokotera.*

# Inception

## Table of Contents
- [Description](#description)
  - [Architecture Overview](#architecture-overview)
- [Project Description & Technical Choices](#project-description--technical-choices)
  - [Design Choices](#design-choices)
  - [Architectural Comparisons](#architectural-comparisons)
    - [1. Virtual Machines vs Docker Containers](#1-virtual-machines-vs-docker-containers)
    - [2. Secrets vs Environment Variables](#2-secrets-vs-environment-variables)
    - [3. Docker Network vs Host Network](#3-docker-network-vs-host-network)
    - [4. Docker Volumes vs Bind Mounts](#4-docker-volumes-vs-bind-mounts)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Managing the Infrastructure](#managing-the-infrastructure)
  - [Accessing the Web Application](#accessing-the-web-application)
- [Resources](#resources)
  - [References & Documentation](#references--documentation)
  - [AI Usage Disclosure](#ai-usage-disclosure)

---

## Description
The **Inception** project consists of designing and setting up a small multi-service infrastructure entirely containerized using **Docker** and **Docker Compose**. 

The goal is to build a secure, isolated, and scalable environment running a WordPress website supported by a MariaDB database and exposed via an NGINX web server over HTTPS. Each service is built from scratch using a dedicated custom Dockerfile

### Architecture Overview

- **NGINX:** The only exposed gateway to the host machine. Operates on port `443` using TLSv1.2/TLSv1.3 with a self-signed SSL certificate. It forwards PHP dynamic requests to WordPress via FastCGI.
- **WordPress (PHP-FPM):** Runs PHP-FPM listening on port `9000` inside the internal Docker network. Interacts with MariaDB to serve website content.
- **MariaDB:** Database server running on port `3306`, storing all user accounts, posts, and configurations. It communicates strictly through the private bridge network.
- **Redis Cache (Bonus):** Dedicated in-memory caching service listening on port `6379` within the private bridge network. It provides object caching for WordPress, storing database query results directly in RAM to drastically reduce MariaDB load and decrease page latency.
- **FTP Server (vsftpd - Bonus):** Secure FTP daemon running on port `21` (with passive range `30000-30100`) mounted directly to the WordPress website volume. Enables remote file management (uploading, editing, and downloading themes, plugins, and media) without requiring direct shell access.
- **Static Website (Bonus):** Standalone static web application running in its own container, reverse-proxied by NGINX under `/website/`.
- **Adminer (Bonus):** Lightweight web-based database management interface for inspecting and querying MariaDB, securely routed through NGINX under `/adminer`.
- **Portainer (Bonus):** Web-based container management and monitoring dashboard connected to the Docker daemon socket, with persistent state under `/home/vokotera/data/portainer`, routed via NGINX under `/portainer/`.

---

## Project Description & Technical Choices

### Design Choices
**Debian Bookworm Base:** Used across all images for uniformity, lightweight footprint, and stability.
**No Ready-Made Images:** All Docker images are built locally without utilizing bloated, pre-configured images from Docker Hub.
- **Foreground Master Processes:** Every service runs its main process with PID 1 in the foreground (`nginx -g 'daemon off;'`, `php-fpm8.2 -F`, `mysqld --user=mysql`) ensuring Docker lifecycle management works accurately.

### Architectural Comparisons

#### 1. Virtual Machines vs Docker Containers
- **Virtual Machines (VMs):** Emulate complete physical hardware using a Hypervisor. Each VM includes its own full guest operating system, kernel, and virtual devices. They provide high isolation at the cost of high CPU/RAM overhead, slower boot times, and large disk images.
- **Docker Containers:** Share the host system's Linux kernel and isolate applications using kernel features. They are lightweight, start in seconds, consume minimal resources, and package only the necessary binaries and libraries.

#### 2. Secrets vs Environment Variables
- **Environment Variables (`.env` / `ENV`):** Suitable for non-sensitive configuration data (e.g., domain names, user names, ports). However, environment variables and error dumps, making them insecure for passwords.
- **Docker Secrets:** Designed specifically for sensitive information (passwords, private keys). Docker mounts secrets as temporary in-memory files, ensuring sensitive data is never baked into image layers, committed to version control, or exposed in process trees.

#### 3. Docker Network vs Host Network
- **Host Network:** Bypasses Docker network isolation entirely. Containers bind directly to the host machine’s network interfaces and share port ranges. This introduces severe security vulnerabilities and port collision risks.
- **Custom Docker Bridge Network:** Creates an isolated internal software bridge (`inception`). Containers get private IP addresses and resolve each other automatically via internal DNS (using service names like `mariadb` and `wordpress`). Only explicitly mapped ports (such as `443` for NGINX) are accessible from outside.


#### 4. Docker Volumes vs Bind Mounts
- **Docker Volumes (Named Volumes):** Managed entirely by Docker inside its storage directory. They are isolated from host filesystem quirks and offer high performance and easy backup, but are less accessible directly on the host.
- **Bind Mounts:** Maps an exact path from the host filesystem directly into the container. In Inception, named local driver bind mounts (`/home/vokotera/data/...`) ensure that persistent databases and web uploads remain directly on the host machine and survive container lifecycle events.

---

## Instructions

### Prerequisites
- Docker Engine & Docker Compose (v2+)
- Host `/etc/hosts` resolution:
  ```text
  127.0.0.1 vokotera.42.fr
  ```
- Secrets directory located at the root of the project:
  ```text
  secrets/
  ├── db_password.txt
  ├── db_root_password.txt
  ├── wp_admin_password.txt
  └── wp_user_password.txt
  ```

### Managing the Infrastructure
The project includes a root [Makefile](file:///home/vokotera/Inception/Makefile) to automate lifecycle tasks:

- **Build and start all services:**
  ```bash
  make
  # or
  make up
  ```
- **Stop services:**
  ```bash
  make down
  ```
- **Deep clean (stops containers, removes networks, volumes, images, and data directories):**
  ```bash
  make fclean
  ```
- **Rebuild and restart from scratch:**
  ```bash
  make re
  ```

### Accessing the Web Application
Open your browser and navigate to:
```text
https://vokotera.42.fr
```
*(Accept the self-signed certificate warning in your browser).*

---

## Resources

### References & Documentation
- [Docker Documentation](https://docs.docker.com/)
- [NGINX Official Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [Redis Official Documentation](https://redis.io/docs/)
- [vsftpd Official Documentation & Configuration](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Adminer Official Documentation](https://www.adminer.org/)
- [Portainer CE Documentation](https://docs.portainer.io/)
- [TLS - YTB VIDEO](https://www.youtube.com/watch?v=AlE5X1NlHgg)
- [NGINX - YTB VIDEO](https://www.youtube.com/watch?v=rNF3QJPlagg&t=600s)

### AI Usage Disclosure
Artificial Intelligence (Google Antigravity / Gemini) was utilized during the development of this project for:
- **Conceptual Clarification:** Explaining Docker container lifecycles, PID 1 foreground execution requirements, and PHP-FPM FastCGI socket/port communication.
- **Debugging & Troubleshooting:** Diagnosing 502 Bad Gateway and 404 Not Found errors between NGINX and WordPress, identifying host-level NGINX port 80 service conflicts, and refining shell conditionals in entrypoint scripts.
- **Documentation:** Assisting in structuring the comparisons in this README according to the 42 project requirements.