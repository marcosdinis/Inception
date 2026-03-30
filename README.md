*This project has been created as part of the 42 curriculum by mdiniz.*

# Inception

## Description

Inception is a system administration project that uses Docker to set up a small infrastructure composed of multiple services. The entire project runs inside a virtual machine and is orchestrated with Docker Compose.

The infrastructure consists of three core services:

- **NGINX** — the only entry point into the infrastructure, serving HTTPS traffic exclusively on port 443 using TLSv1.2 or TLSv1.3.
- **WordPress + PHP-FPM** — the web application, running without NGINX inside its own container.
- **MariaDB** — the relational database used by WordPress, running in an isolated container.

All services communicate through a dedicated Docker network. Data is persisted using named Docker volumes for both the WordPress database and the WordPress website files.

### Design choices

**Virtual Machines vs Docker**

A virtual machine emulates an entire operating system, including its own kernel, hardware drivers, and system libraries. This makes VMs heavy and slow to start. Docker containers, by contrast, share the host kernel and isolate only the application and its dependencies using Linux namespaces and cgroups. Containers are lightweight, start in seconds, and are more efficient with system resources. The trade-off is that containers provide weaker isolation than VMs — a compromised container can potentially affect the host kernel.

**Secrets vs Environment Variables**

Environment variables are the simplest way to pass configuration to containers, but they have security drawbacks: they are visible via `docker inspect`, inherited by child processes, and often captured in logs. Docker Secrets store sensitive values as files mounted in memory (`/run/secrets/`) inside the container. They are not exposed through the Docker API, are not inherited by subprocesses, and never appear in image layers or logs. This project uses secrets for all passwords and credentials, and environment variables only for non-sensitive configuration such as usernames, domain names, and database names.

**Docker Network vs Host Network**

With `network: host`, the container shares the host's network stack directly, meaning it can bind to any port on the host and communicate with all host interfaces. This eliminates network isolation entirely. A Docker bridge network creates an isolated virtual network where containers can reach each other by service name (DNS resolution) but are isolated from the host and from other networks. This project uses a dedicated bridge network (`inception_net`) so containers communicate securely without exposing unnecessary ports to the host.

**Docker Volumes vs Bind Mounts**

A bind mount maps a specific path on the host filesystem directly into the container. This is simple but creates a tight coupling between the host and the container — the host path must exist and the container depends on its structure. Named Docker volumes are managed by Docker itself: Docker handles the storage location, permissions, and lifecycle. They are more portable, easier to back up, and work correctly across different environments. This project uses named volumes with a local driver configured to store data in `/home/mdiniz/data/` on the host.

## Instructions

### Prerequisites

- A virtual machine running Debian or Alpine Linux
- Docker and Docker Compose installed
- `make` installed

### Installation and execution

Clone the repository and run:

```sh
make
```

This will:
1. Create the required data directories on the host
2. Build all Docker images from their respective Dockerfiles
3. Start all containers

To stop the infrastructure:

```sh
make down
```

To remove all containers, images, and data:

```sh
make fclean
```

To rebuild everything from scratch:

```sh
make re
```

### Accessing the site

Add the following line to `/etc/hosts` on your machine:

```
127.0.0.1    mdiniz.42.fr
```

Then open your browser and navigate to:

```
https://mdiniz.42.fr
```

Accept the self-signed certificate warning. The WordPress site will load. The administration panel is available at `https://mdiniz.42.fr/wp-admin`.

## Resources

### Documentation and references

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WordPress documentation](https://developer.wordpress.org/)
- [WP-CLI documentation](https://wp-cli.org/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL documentation](https://www.openssl.org/docs/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker secrets overview](https://docs.docker.com/engine/swarm/secrets/)

### Use of AI

Claude (Anthropic) was used as a learning and guidance tool throughout this project. Specifically:

- To understand and explain Docker concepts such as named volumes, secrets, networks, and PID 1 behaviour.
- To review Dockerfiles and shell scripts for security issues (hardcoded passwords, use of `latest` tag, improper entrypoints).
- To help debug issues such as container startup failures, volume mount errors, and PHP-FPM connectivity problems.
- To generate initial versions of configuration files (`nginx.conf`, `www.conf`, `init.sh` scripts) which were then reviewed, tested, and adapted.

All AI-generated content was reviewed, understood, and validated before being included in the project. No code was copied without understanding its purpose and behaviour.
