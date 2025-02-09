RED	:= $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
MAGENTA:= $(shell tput -Txterm setaf 5)
CYAN   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

SRC_DIR = ./srcs
DC = docker-compose -f $(SRC_DIR)/docker-compose.yml -f $(SRC_DIR)/docker-compose.override.yml
APP_VERSION = 0.0.1
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

build: check-create-volume check-create-network init-env generate-override
	@echo "$(BLUE)Building base image...$(RESET)"
	@$(DC) build base --no-cache
	@if [ "$$(docker images -q inception/base:$(APP_VERSION))" = "" ]; then \
		echo "$(RED)Error: Failed to build base image$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Base image has been built.$(RESET)"
	@echo "$(BLUE)Building other images...$(RESET)"
	@$(DC) build nginx wordpress db --no-cache --parallel || true
	@if [ "$$(docker images -q inception/nginx:$(APP_VERSION))" = "" ] || \
		[ "$$(docker images -q inception/wordpress:$(APP_VERSION))" = "" ] || \
		[ "$$(docker images -q inception/db:$(APP_VERSION))" = "" ]; then \
		echo "$(RED)Error: Failed to build other images$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Other images have been built.$(RESET)"

run: build
	@echo "$(GREEN)Starting services...$(RESET)"
	@$(DC) up -d

clean:
	@echo "$(YELLOW)Stopping and removing containers...$(RESET)"
	@$(DC) down
	@echo "$(YELLOW)Removing volumes and networks...$(RESET)"
	@docker volume rm $(VOLUME_WP) || true
	@docker volume rm $(VOLUME_DB) || true
	@docker network rm $(NETWORK_CNGINX_CWP) || true
	@docker network rm $(NETWORK_CNGINX_WP) || true
	@docker network rm $(NETWORK_CWP_CDB) || true
	@docker network rm $(NETWORK_WP) || true
	@docker network rm $(NETWORK_DB) || true

re: clean run

fclean: clean
	@echo "$(RED)Removing all project images...$(RESET)"
	@docker rmi -f $(shell docker images "inception/*" -q) || true

logs:
	@echo "$(CYAN)Showing logs...$(RESET)"
	@$(DC) logs -f

check-create-volume:
	@echo "$(BLUE)Checking and creating volumes...$(RESET)"
	@for vol in $(VOLUME_WP) $(VOLUME_DB); do \
		if [ -z "$$(docker volume ls -q -f name=$$vol)" ]; then \
			echo "$(YELLOW)Docker volume $$vol does not exist. Creating...$(RESET)"; \
			docker volume create $$vol; \
		else \
			echo "$(GREEN)Docker volume $$vol already exists.$(RESET)"; \
		fi; \
	done

check-create-network:
	@echo "$(BLUE)Checking and creating networks...$(RESET)"
	@for net in $(NETWORK_CNGINX_CWP) $(NETWORK_CNGINX_WP) $(NETWORK_CWP_CDB) $(NETWORK_WP) $(NETWORK_DB); do \
		if [ -z "$$(docker network ls -q -f name=$$net)" ]; then \
			echo "$(YELLOW)Docker network $$net does not exist. Creating...$(RESET)"; \
			docker network create $$net; \
		else \
			echo "$(GREEN)Docker network $$net already exists.$(RESET)"; \
		fi; \
	done

init-env:
	@echo "$(BLUE)Initializing environment variables...$(RESET)"
	$(eval USER_NAME=$(shell whoami))
	$(eval RANDOM_PASSWORD=$(shell openssl rand -base64 12))
	@echo "Creating .env file..."
	@echo "# $(SRC_DIR)/.env" > $(SRC_DIR)/.env
	@echo "# Basic setup" >> $(SRC_DIR)/.env
	@echo "OS=$(OS)" >> $(SRC_DIR)/.env
	@echo "OS_VERSION=$(OS_VERSION)" >> $(SRC_DIR)/.env
	@echo "APP_VERSION=$(APP_VERSION)" >> $(SRC_DIR)/.env
	@echo "DOMAIN_NAME=$(USER_NAME).42.fr" >> $(SRC_DIR)/.env
	@echo "\n# DB setup" >> $(SRC_DIR)/.env
	@echo "MYSQL_ROOT_PASSWORD=$(RANDOM_PASSWORD)" >> $(SRC_DIR)/.env
	@echo "MYSQL_USER=$(USER_NAME)" >> $(SRC_DIR)/.env
	@echo "MYSQL_PASSWORD=$(RANDOM_PASSWORD)" >> $(SRC_DIR)/.env
	@echo "\n# Docker-compose setup" >> $(SRC_DIR)/.env
	@echo "VOLUME_WP=$(VOLUME_WP)" >> $(SRC_DIR)/.env
	@echo "VOLUME_DB=$(VOLUME_DB)" >> $(SRC_DIR)/.env
	@echo "NETWORK_CNGINX_CWP=$(NETWORK_CNGINX_CWP)" >> $(SRC_DIR)/.env
	@echo "NETWORK_CNGINX_WP=$(NETWORK_CNGINX_WP)" >> $(SRC_DIR)/.env
	@echo "NETWORK_CWP_CDB=$(NETWORK_CWP_CDB)" >> $(SRC_DIR)/.env
	@echo "NETWORK_WP=$(NETWORK_WP)" >> $(SRC_DIR)/.env
	@echo "NETWORK_DB=$(NETWORK_DB)" >> $(SRC_DIR)/.env

generate-override:
	@echo "$(BLUE)Generating docker-compose.override.yml...$(RESET)"
	@sed 's/NETWORK_CNGINX_CWP_PLACEHOLDER/$(NETWORK_CNGINX_CWP)/g; \
		s/NETWORK_CNGINX_WP_PLACEHOLDER/$(NETWORK_CNGINX_WP)/g; \
		s/NETWORK_CWP_CDB_PLACEHOLDER/$(NETWORK_CWP_CDB)/g; \
		s/NETWORK_WP_PLACEHOLDER/$(NETWORK_WP)/g; \
		s/NETWORK_DB_PLACEHOLDER/$(NETWORK_DB)/g; \
		s/VOLUME_WP_PLACEHOLDER/$(VOLUME_WP)/g; \
		s/VOLUME_DB_PLACEHOLDER/$(VOLUME_DB)/g' \
		$(SRC_DIR)/docker-compose.override.yml.template > $(SRC_DIR)/docker-compose.override.yml
	@echo "$(GREEN)docker-compose.override.yml has been generated.$(RESET)"

help:
	@echo "$(CYAN)Available targets:$(RESET)"
	@echo "  $(YELLOW)build$(RESET)   - Build Docker images"
	@echo "  $(YELLOW)run$(RESET)     - Build and start services"
	@echo "  $(YELLOW)clean$(RESET)   - Stop and remove containers, volumes, and networks"
	@echo "  $(YELLOW)re$(RESET)      - Rebuild and restart services"
	@echo "  $(YELLOW)fclean$(RESET)  - Perform clean and remove all project images"
	@echo "  $(YELLOW)logs$(RESET)    - Show service logs"

.PHONY: default build run clean re fclean logs check-create-volume check-create-network init-env generate-override help
