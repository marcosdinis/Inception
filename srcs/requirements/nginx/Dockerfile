FROM debian:12
ARG DOMAIN_NAME
RUN apt update -y && apt install nginx openssl && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=AO/ST=Luanda/L=Luanda/O=42Luanda/OU=Inception/CN=$DOMAIN_NAME/"
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
