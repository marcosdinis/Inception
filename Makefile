COMPOSE_FILE = srcs/docker-compose.yml

all: up

up:
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down -v

re: down all

.PHONY: all up down re
