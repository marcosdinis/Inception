#!/bin/sh
set -e

# Cria a pasta para o certificado SSL
mkdir -p /etc/nginx/ssl

# Gera o certificado self-signed se ainda não existir
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out    /etc/nginx/ssl/nginx.crt \
        -subj   "/C=PT/ST=Lisboa/L=Lisboa/O=42/CN=${DOMAIN_NAME}"
fi

# Inicia o NGINX como processo principal
exec nginx -g "daemon off;"