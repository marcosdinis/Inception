DATA_PATH = /home/marcos/data

all:
	@mkdir -p $(DATA_PATH)/wordpress $(DATA_PATH)/mariadb
	@docker compose -f srcs/docker-compose.yml up --build -d

down:
	@docker compose -f srcs/docker-compose.yml down

stop:
	@docker compose -f srcs/docker-compose.yml stop

clean: down
	@docker system prune -af
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true

fclean: clean
	@sudo rm -rf $(DATA_PATH)

re: fclean all

.PHONY: all down stop clean fclean re