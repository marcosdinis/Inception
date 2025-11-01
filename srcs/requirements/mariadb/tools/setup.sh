#!/bin/bash

#Iniciar o servidor em background para executar os comandos MYSQL
/usr/bin/mysqld_safe --datadir='/var/lib/mysql' &

#Verifica se o processo mariadbd já está a aceitar conexões na porta 3306
#caso não aguarda e tenta novamente a cada 2 segundos.
until mariadb-admin ping; do
	echo "Aguardando o servidor MariaDB..."
	sleep 2
done

echo "O servidor está pronto. Configurando utilizador e a base de dados..."

mariadb -u root <<EOF
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\'@'%';
	FLUSH PRIVILEGES;
EOF

echo "Configuração inicial do MariaDB concluída"

mariadb-admin shutdown

echo "Servidor MariaDB temporário encerrado. Iniciando o servidor principal..."

exec mariadbd
