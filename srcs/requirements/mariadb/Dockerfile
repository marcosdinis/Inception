FROM debian:12
RUN apt-get update -y && apt-get install mariadb-server -y && rm -rf /var/lib/apt/lists/*
EXPOSE 3306
COPY /tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh
ENTRYPOINT ["/usr/local/bin/setup.sh"]
