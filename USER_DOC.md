# User documentation

## What this stack provides

This infrastructure runs a WordPress website accessible via HTTPS. It is composed of three services:

- **NGINX** — receives all incoming HTTPS requests on port 443 and forwards PHP requests to WordPress. It is the only service directly accessible from outside the infrastructure.
- **WordPress** — the content management system. It handles page rendering and communicates with the database to store and retrieve content.
- **MariaDB** — the database that stores all WordPress data: posts, users, settings, and media metadata.

All three services run in isolated containers on a shared internal network. No service is accessible directly from outside except NGINX on port 443.

---

## Starting and stopping the project

### Start

From the root of the repository:

```sh
make
```

Wait until you see all three containers running. You can verify with:

```sh
docker ps
```

You should see `nginx`, `wordpress`, and `mariadb` with status `Up`.

### Stop (keeps data)

```sh
make down
```

This stops and removes the containers but keeps all volumes and data intact. Running `make` again will restore everything.

### Full reset (deletes all data)

```sh
make fclean
```

This removes all containers, images, volumes, and data. Use this only if you want to start completely from scratch.

---

## Accessing the website

Make sure your `/etc/hosts` file contains this line:

```
127.0.0.1    marcos.42.fr
```

Then open your browser and go to:

```
https://marcos.42.fr
```

Your browser will show a security warning because the SSL certificate is self-signed. This is expected. Click **Advanced** and then **Proceed to marcos.42.fr** to continue.

### Administration panel

The WordPress admin panel is available at:

```
https://marcos.42.fr/wp-admin
```

Log in with the administrator credentials stored in `secrets/credentials.txt`.

---

## Locating and managing credentials

All credentials are stored in the `secrets/` folder at the root of the repository. This folder must never be committed to Git.

| File | Contains |
|------|----------|
| `secrets/credentials.txt` | WordPress administrator password |
| `secrets/db_password.txt` | MariaDB user password (used by WordPress) |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/wp_user_password.txt` | WordPress second user password |

Non-sensitive configuration (usernames, domain name, database name) is stored in `srcs/.env`.

To change a password, edit the corresponding file in `secrets/`, then run:

```sh
make fclean
make
```

---

## Checking that services are running correctly

### Quick status check

```sh
docker ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should show status `Up`.

### Check NGINX is accepting HTTPS connections

```sh
curl -k https://marcos.42.fr | head -5
```

You should see the beginning of the WordPress HTML page.

### Check that port 80 is not accessible (required by the project)

```sh
curl http://marcos.42.fr
```

This should fail with `Failed to connect to marcos.42.fr port 80`. If it connects, there is a configuration problem.

### Check PHP-FPM is running inside the WordPress container

```sh
docker exec wordpress ps aux | grep php
```

You should see `php-fpm: master process` and at least two worker processes.

### Check the WordPress database connection

```sh
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
```

No output means WordPress is installed and connected to the database. An error means the database connection is failing.

### Check WordPress users

```sh
docker exec wordpress wp user list --path=/var/www/html --allow-root
```

You should see two users: one with role `administrator` and one with role `author`.

### View container logs

```sh
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Use these commands to diagnose errors if a container is not behaving as expected.
