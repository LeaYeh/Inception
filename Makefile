DC = docker-compose -f srcs/docker-compose.yml -f srcs/docker-compose.override.yml
OS = alpine
OS_VERSION = 3.19
VOLUME_WP = wp-files
VOLUME_DB = db-data
NETWORK_CNGINX_CWP = network-cnginx-cwp
NETWORK_CNGINX_WP = network-cnginx-wp
NETWORK_CWP_CDB = network-cwp-cdb
NETWORK_WP = network-wp
NETWORK_DB = network-db

default: run

run: check-create-volume check-create-network init-env generate-override
	$(DC) up -d

clean:
	$(DC) down

re: clean run

clean:
	$(DC) down
	docker volume rm $(VOLUME_WP)
	docker volume rm $(VOLUME_DB)
	docker network rm $(NETWORK_CNGINX_CWP)
	docker network rm $(NETWORK_CNGINX_WP)
	docker network rm $(NETWORK_CWP_CDB)
	docker network rm $(NETWORK_WP)
	docker network rm $(NETWORK_DB)

fclean: clean
	docker rmi -f $(shell docker images -q)

logs:
	$(DC) logs -f

check-create-volume:
	@echo "Check if volume $(VOLUME_WP) exists..."
	@if [ -z "$$(docker volume ls -q -f name=$(VOLUME_WP))" ]; then \
		echo "Docker volume $(VOLUME_WP) does not exist. Creating..."; \
		docker volume create $(VOLUME_WP); \
	else \
		echo "Docker volume $(VOLUME_WP) already exists."; \
	fi
	@echo "Check if volume $(VOLUME_DB) exists..."
	@if [ -z "$$(docker volume ls -q -f name=$(VOLUME_DB))" ]; then \
		echo "Docker volume $(VOLUME_DB) does not exist. Creating..."; \
		docker volume create $(VOLUME_DB); \
	else \
		echo "Docker volume $(VOLUME_DB) already exists."; \
	fi

check-create-network:
	@echo "Check if network $(NETWORK_CNGINX_CWP) exists..."
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_CNGINX_CWP))" ]; then \
		echo "Docker network $(NETWORK_CNGINX_CWP) does not exist. Creating..."; \
		docker network create $(NETWORK_CNGINX_CWP); \
	else \
		echo "Docker network $(NETWORK_CNGINX_CWP) already exists."; \
	fi
	@echo "Check if network $(NETWORK_CNGINX_WP) exists..."
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_CNGINX_WP))" ]; then \
		echo "Docker network $(NETWORK_CNGINX_WP) does not exist. Creating..."; \
		docker network create $(NETWORK_CNGINX_WP); \
	else \
		echo "Docker network $(NETWORK_CNGINX_WP) already exists."; \
	fi
	@echo "Check if network $(NETWORK_CWP_CDB) exists..."
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_CWP_CDB))" ]; then \
		echo "Docker network $(NETWORK_CWP_CDB) does not exist. Creating..."; \
		docker network create $(NETWORK_CWP_CDB); \
	else \
		echo "Docker network $(NETWORK_CWP_CDB) already exists."; \
	fi
	@echo "Check if network $(NETWORK_WP) exists..."
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_WP))" ]; then \
		echo "Docker network $(NETWORK_WP) does not exist. Creating..."; \
		docker network create $(NETWORK_WP); \
	else \
		echo "Docker network $(NETWORK_WP) already exists."; \
	fi
	@echo "Check if network $(NETWORK_DB) exists..."
	@if [ -z "$$(docker network ls -q -f name=$(NETWORK_DB))" ]; then \
		echo "Docker network $(NETWORK_DB) does not exist. Creating..."; \
		docker network create $(NETWORK_DB); \
	else \
		echo "Docker network $(NETWORK_DB) already exists."; \
	fi
	
init-env:
	$(eval USER_NAME=$(shell whoami))
	$(eval RANDOM_PASSWORD=$(shell openssl rand -base64 12))
	@echo "Creating .env file..."
	@echo "# srcs/.env" > srcs/.env
	@echo "# Basic setup" >> srcs/.env
	@echo "OS=$(OS)" > srcs/.env
	@echo "OS_VERSION=$(OS_VERSION)" >> srcs/.env
	@echo "DOMAIN_NAME=$(USER_NAME).42.fr" >> srcs/.env
	@echo "# DB setup" >> srcs/.env
	@echo "MYSQL_ROOT_PASSWORD=$(RANDOM_PASSWORD)" >> srcs/.env
	@echo "MYSQL_USER=$(USER_NAME)" >> srcs/.env
	@echo "MYSQL_PASSWORD=$(RANDOM_PASSWORD)" >> srcs/.env
	@echo "# Docker-compose setup" >> srcs/.env
	@echo "VOLUME_WP=$(VOLUME_WP)" >> srcs/.env
	@echo "VOLUME_DB=$(VOLUME_DB)" >> srcs/.env
	@echo "NETWORK_CNGINX_CWP=$(NETWORK_CNGINX_CWP)" >> srcs/.env
	@echo "NETWORK_CNGINX_WP=$(NETWORK_CNGINX_WP)" >> srcs/.env
	@echo "NETWORK_CWP_CDB=$(NETWORK_CWP_CDB)" >> srcs/.env
	@echo "NETWORK_WP=$(NETWORK_WP)" >> srcs/.env
	@echo "NETWORK_DB=$(NETWORK_DB)" >> srcs/.env

generate-override:
	@echo "Generating docker-compose.override.yml..."
	@sed 's/NETWORK_CNGINX_CWP_PLACEHOLDER/$(NETWORK_CNGINX_CWP)/g; \
         s/NETWORK_CNGINX_WP_PLACEHOLDER/$(NETWORK_CNGINX_WP)/g; \
         s/NETWORK_CWP_CDB_PLACEHOLDER/$(NETWORK_CWP_CDB)/g; \
         s/NETWORK_WP_PLACEHOLDER/$(NETWORK_WP)/g; \
         s/NETWORK_DB_PLACEHOLDER/$(NETWORK_DB)/g; \
         s/VOLUME_WP_PLACEHOLDER/$(VOLUME_WP)/g; \
         s/VOLUME_DB_PLACEHOLDER/$(VOLUME_DB)/g' \
         srcs/docker-compose.override.yml.template > srcs/docker-compose.override.yml
	@echo "docker-compose.override.yml has been generated."