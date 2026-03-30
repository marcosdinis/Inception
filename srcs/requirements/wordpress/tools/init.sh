#!/bin/sh
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

# Aguarda o MariaDB estar disponível antes de continuar
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    echo "A aguardar MariaDB..."
    sleep 2
done

# Só instala o WordPress se ainda não estiver instalado
if [ ! -f "/var/www/html/wp-config.php" ]; then

    # Descarrega o WordPress
    wp core download --path=/var/www/html --allow-root

    # Cria o wp-config.php com as variáveis do .env
    wp config create \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Instala o WordPress
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # Cria o segundo utilizador (não administrador)
    wp user create \
        --path=/var/www/html \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root

    # Corrige permissões
    chown -R www-data:www-data /var/www/html
fi

# Inicia o PHP-FPM como processo principal (PID 1)
exec php-fpm8.2 -F