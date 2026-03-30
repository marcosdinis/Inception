# Developer documentation

## Prerequisites

Before setting up the project, make sure the following are installed on your virtual machine:

- Docker (tested with version 29+)
- Docker Compose (included with Docker Desktop or installed separately)
- `make`
- `git`

To verify:

```sh
docker --version
docker compose version
make --version
```

---

## Repository structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt        ← WordPress admin password
│   ├── db_password.txt        ← MariaDB user password
│   ├── db_root_password.txt   ← MariaDB root password
│   └── wp_user_password.txt   ← WordPress second user password
└── srcs/
    ├── .env                   ← Non-sensitive environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── init.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── init.sh
```

---

## Setting up from scratch

### 1. Clone the repository

```sh
git clone <repository-url>
cd inception
```

### 2. Create the secrets files

These files are not committed to Git. Create them manually:

```sh
echo "your_root_password"  > secrets/db_root_password.txt
echo "your_db_password"    > secrets/db_password.txt
echo "your_admin_password" > secrets/credentials.txt
echo "your_user_password"  > secrets/wp_user_password.txt
```

Passwords must not contain single quotes — they are passed directly to MariaDB and WordPress CLI commands.

### 3. Review the .env file

`srcs/.env` contains all non-sensitive configuration. Review and adjust if needed:

```env
DOMAIN_NAME=mdiniz.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=marcos

WP_TITLE=Inception
WP_ADMIN_USER=mdiniz
WP_ADMIN_EMAIL=mdiniz@42.fr
WP_USER=diniz
WP_USER_EMAIL=diniz@42.fr
```

`WP_ADMIN_USER` must not contain `admin` or `administrator` in any form — this is a hard requirement of the project evaluation.

### 4. Configure the local domain

Add the following line to `/etc/hosts` on your machine:

```sh
echo "127.0.0.1    mdiniz.42.fr" | sudo tee -a /etc/hosts
```

### 5. Build and launch

```sh
sudo make
```

The Makefile creates the required host directories and runs `docker compose up --build`. The first build takes several minutes as it downloads base images and installs packages.

---

## Building and launching with Make

| Command | Effect |
|---------|--------|
| `make` or `make all` | Creates data directories, builds images, starts containers |
| `make down` | Stops and removes containers, keeps volumes and data |
| `make clean` | Stops containers and removes images |
| `make fclean` | Full reset — removes containers, images, volumes, and host data |
| `make re` | Runs `fclean` then `all` |

---

## Managing containers and volumes

### View running containers

```sh
docker ps
```

### View logs for a specific service

```sh
docker logs mariadb
docker logs wordpress
docker logs nginx
```

To follow logs in real time:

```sh
docker logs -f wordpress
```

### Execute a command inside a container

```sh
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

### Restart a single container

```sh
docker restart wordpress
```

### Rebuild a single service without rebuilding others

```sh
docker compose -f srcs/docker-compose.yml up --build wordpress
```

### View volumes

```sh
docker volume ls
```

### Inspect a volume

```sh
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_files
```

---

## Where data is stored and how it persists

### Named volumes

The project uses two named Docker volumes:

| Volume | Purpose | Host path |
|--------|---------|-----------|
| `srcs_mariadb_data` | MariaDB database files | `/home/mdiniz/data/mariadb` |
| `srcs_wordpress_files` | WordPress application files | `/home/mdiniz/data/wordpress` |

These volumes persist across container restarts and `make down`. Data is only deleted when running `make fclean`, which removes the volumes and clears the host directories.

### Persistence behaviour

When a container starts for the first time, the `init.sh` script checks whether data already exists before initialising:

- **MariaDB** — checks for `/var/lib/mysql/mysql`. If it exists, skips database initialisation and starts the server directly.
- **WordPress** — checks for `/var/www/html/wp-config.php`. If it exists, skips the download and installation steps and starts PHP-FPM directly.

This means that after a `make down` + `make`, all previously created posts, users, and settings are preserved.

### SSL certificate

The NGINX `init.sh` generates a self-signed SSL certificate at `/etc/nginx/ssl/nginx.crt` on first start. This certificate is stored inside the container and is recreated each time the container is rebuilt.

---

## How secrets are passed to containers

Secrets are declared in `docker-compose.yml` and mounted as read-only files in `/run/secrets/` inside each container. The `init.sh` scripts read them with:

```sh
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
```

Secrets never appear in environment variables, image layers, or `docker inspect` output. Non-sensitive values (usernames, domain, database name) are passed via `env_file: .env`.

---

## Common issues and solutions

### Container fails to start with "no such file or directory" on volume mount

The host data directories do not exist. Run:

```sh
mkdir -p /home/mdiniz/data/mariadb
mkdir -p /home/mdiniz/data/wordpress
```

Or simply run `make fclean && make` — the Makefile creates these directories automatically.

### WordPress keeps printing "A aguardar MariaDB..."

MariaDB is taking longer than expected to start, or the credentials in `secrets/db_password.txt` do not match `MYSQL_USER` in `.env`. Check MariaDB logs:

```sh
docker logs mariadb
```

### "Too Many Requests" error when building images

Docker Hub rate-limits unauthenticated pulls. Log in to Docker Hub:

```sh
docker login
```

Then retry the build.

### Site redirects to the wrong domain after changing DOMAIN_NAME

WordPress stores the site URL in the database. After changing the domain, you must do a full reset:

```sh
make fclean
make
```
