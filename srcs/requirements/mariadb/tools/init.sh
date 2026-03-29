#!/bin/sh
set -e

# Lê a password root do ficheiro de secrets (nunca hardcoded)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Inicializa os ficheiros da base de dados se ainda não existirem
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Inicia o MariaDB temporariamente em modo silencioso para configurar
mysqld_safe --nowatch &
MYSQL_PID=$!

# Aguarda o MariaDB estar pronto para aceitar ligações
until mysqladmin ping --silent; do
    sleep 1
done

# Executa todos os comandos SQL de configuração de uma vez
mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Para o processo temporário e entrega o controlo ao processo principal
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID

# Inicia o MariaDB como processo principal (PID 1) — sem tail -f nem sleep
exec mysqld_safe