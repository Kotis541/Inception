NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR	= /home/vokotera/data

all: create_dirs up

up:	create_dirs
	docker compose -f $(COMPOSE_FILE) up --build -d

down:
	docker compose -f $(COMPOSE_FILE) down

create_dirs:
	@if [ ! -d "$(DATA_DIR)/mariadb" ]; then \
		mkdir -p $(DATA_DIR)/mariadb; \
		echo "Created $(DATA_DIR)/mariadb"; \
	fi
	@if [ ! -d "$(DATA_DIR)/wordpress" ]; then \
		mkdir -p $(DATA_DIR)/wordpress; \
		echo "Created $(DATA_DIR)/wordpress"; \
	fi
	@if [ ! -d "$(DATA_DIR)/portainer" ]; then \
		mkdir -p $(DATA_DIR)/portainer; \
		echo "Created $(DATA_DIR)/portainer"; \
	fi

clean: down

fclean:
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	docker run --rm -v $(DATA_DIR):/data debian:bookworm rm -rf /data/mariadb /data/wordpress /data/portainer
	docker system prune -af

re: fclean all

.PHONY: all up down create_dirs fclean re