RED	:= $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
MAGENTA:= $(shell tput -Txterm setaf 5)
CYAN   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

SRC_DIR = ./srcs
DC = docker compose -f $(SRC_DIR)/docker-compose.yml -f $(SRC_DIR)/docker-compose.override.yml
APP_VERSION = 0.0.1
OS = alpine
OS_VERSION = 3.19
VOLUME_WP = wp-files
VOLUME_DB = db-data
NETWORK = inception-network

SERVICES := nginx db wordpress

default: run

build-base: check-create-volume check-create-network init-env generate-override
	@echo "$(BLUE)Building base image...$(RESET)"
	@$(DC) build base --no-cache
	@echo "$(BLUE)Checking base image...$(RESET)"
	@docker image inspect inception/base:$(APP_VERSION) > /dev/null 2>&1 || (echo "$(RED)Base image not found$(RESET)" && exit 1)
	@echo "$(GREEN)Base image has been built: inception/base:$(APP_VERSION)$(RESET)"

build: build-base
	@echo "$(BLUE)Building other images...$(RESET)"
	@$(DC) --verbose build $(SERVICES) --no-cache --parallel || true
	@if [ "$$(docker images -q inception/nginx:$(APP_VERSION))" = "" ] || \
		[ "$$(docker images -q inception/wordpress:$(APP_VERSION))" = "" ] || \
		[ "$$(docker images -q inception/mariadb:$(APP_VERSION))" = "" ]; then \
		echo "$(RED)Error: Failed to build other images$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Other images have been built.$(RESET)"

run: build
	@echo "$(GREEN)Starting services...$(RESET)"
	@$(DC) up -d
	@echo "$(YELLOW)Waiting for services to start...$(RESET)"
	@sleep 10
	@echo "$(YELLOW)Checking service status...$(RESET)"
	@for service in $(SERVICES); do \
		if $(DC) ps --services --filter "status=running" | grep -q $$service; then \
			echo "$(GREEN)$$service is running.$(RESET)"; \
		else \
			echo "$(RED)$$service is not running.$(RESET)"; \
			$(DC) logs $$service; \
			exit 1; \
		fi; \
	done
	@echo "$(GREEN)All services are running.$(RESET)"
	@echo "$(YELLOW)Checking network connectivity...$(RESET)"
	@if docker exec $$($(DC) ps -q wordpress) ping -c 2 db > /dev/null 2>&1; then \
		echo "$(GREEN)WordPress can connect to the database.$(RESET)"; \
	else \
		echo "$(RED)WordPress cannot connect to the database.$(RESET)"; \
		docker exec $$($(DC) ps -q wordpress) ping -c 2 db; \
		exit 1; \
	fi
	@echo "$(GREEN)Setup completed successfully.$(RESET)"

clean:
	@echo "$(YELLOW)Stopping and removing containers...$(RESET)"
	@$(DC) down
	@echo "$(YELLOW)Removing volumes and networks...$(RESET)"
	@docker volume rm $(VOLUME_WP) || true
	@docker volume rm $(VOLUME_DB) || true
	@docker network rm $(NETWORK) || true

re: clean run

re-service: build-base
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE is not specified. Usage: make re-service SERVICE=<service_name>$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Rebuilding service: $(SERVICE)$(RESET)"
	@$(DC) stop $(SERVICE)
	@$(DC) rm -f $(SERVICE)
	@DOCKER_BUILDKIT=0 $(DC) build --no-cache $(SERVICE)
	@$(DC) up -d $(SERVICE)
	@echo "$(GREEN)Service $(SERVICE) has been rebuilt and restarted.$(RESET)"
	@echo "$(YELLOW)Checking service status...$(RESET)"
	@if $(DC) ps --services --filter "status=running" | grep -q $(SERVICE); then \
		echo "$(GREEN)$(SERVICE) is running.$(RESET)"; \
	else \
		echo "$(RED)$(SERVICE) is not running.$(RESET)"; \
		$(DC) logs $(SERVICE); \
		exit 1; \
	fi

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
	@for net in $(NETWORK); do \
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
	@echo "Creating .env file..."
	@echo "# $(SRC_DIR)/.env" > $(SRC_DIR)/.env
	@echo "# Basic setup" >> $(SRC_DIR)/.env
	@echo "OS=$(OS)" >> $(SRC_DIR)/.env
	@echo "OS_VERSION=$(OS_VERSION)" >> $(SRC_DIR)/.env
	@echo "APP_VERSION=$(APP_VERSION)" >> $(SRC_DIR)/.env
	@echo "DOMAIN_NAME=$(USER_NAME).42.fr" >> $(SRC_DIR)/.env
	@echo "\n# DB setup" >> $(SRC_DIR)/.env
	@echo "MYSQL_ROOT_PASSWORD=$(shell openssl rand -base64 12)" >> $(SRC_DIR)/.env
	@echo "MYSQL_ADMIN=$(USER_NAME)" >> $(SRC_DIR)/.env
	@echo "MYSQL_ADMIN_PASSWORD=$(shell openssl rand -base64 12)" >> $(SRC_DIR)/.env
	@echo "MYSQL_ADMIN_EMAIL=$(USER_NAME)@42.fr" >> $(SRC_DIR)/.env
	@echo "MYSQL_DATABASE=wordpress" >> $(SRC_DIR)/.env
	@echo "MYSQL_USER=wordpress" >> $(SRC_DIR)/.env
	@echo "MYSQL_USER_PASSWORD=$(shell openssl rand -base64 12)" >> $(SRC_DIR)/.env
	@echo "MYSQL_USER_EMAIL=wordpress@42.fr" >> $(SRC_DIR)/.env
	@echo "\n# Docker-compose setup" >> $(SRC_DIR)/.env
	@echo "VOLUME_WP=$(VOLUME_WP)" >> $(SRC_DIR)/.env
	@echo "VOLUME_DB=$(VOLUME_DB)" >> $(SRC_DIR)/.env
	@echo "NETWORK=$(NETWORK)" >> $(SRC_DIR)/.env

generate-override:
	@echo "$(BLUE)Generating docker-compose.override.yml...$(RESET)"
	@sed -e 's#NETWORK_PLACEHOLDER#$(NETWORK)#g' \
		-e 's#VOLUME_WP_PLACEHOLDER#$(VOLUME_WP)#g' \
		-e 's#VOLUME_DB_PLACEHOLDER#$(VOLUME_DB)#g' \
		$(SRC_DIR)/docker-compose.override.yml.template > $(SRC_DIR)/docker-compose.override.yml
	@echo "$(GREEN)docker-compose.override.yml has been generated.$(RESET)"

help:
	@echo "$(CYAN)Available targets:$(RESET)"
	@echo "  $(YELLOW)build$(RESET)        - Build Docker images"
	@echo "  $(YELLOW)run$(RESET)          - Build and start services"
	@echo "  $(YELLOW)clean$(RESET)        - Stop and remove containers, volumes, and networks"
	@echo "  $(YELLOW)re$(RESET)           - Rebuild and restart services"
	@echo "  $(YELLOW)re-service$(RESET)   - Rebuild and restart a specific service. Usage: make re-service SERVICE=<service_name>"
	@echo "  $(YELLOW)fclean$(RESET)       - Perform clean and remove all project images"
	@echo "  $(YELLOW)logs$(RESET)         - Show service logs"

.PHONY: default build run clean re re-service fclean logs check-create-volume check-create-network init-env generate-override help
