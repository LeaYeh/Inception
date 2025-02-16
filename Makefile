RED    				:= $(shell tput -Txterm setaf 1)
GREEN  				:= $(shell tput -Txterm setaf 2)
YELLOW 				:= $(shell tput -Txterm setaf 3)
BLUE   				:= $(shell tput -Txterm setaf 4)
MAGENTA				:= $(shell tput -Txterm setaf 5)
CYAN   				:= $(shell tput -Txterm setaf 6)
WHITE  				:= $(shell tput -Txterm setaf 7)
RESET  				:= $(shell tput -Txterm sgr0)

# Configuration
USER_NAME			= $(shell whoami)
DIR_SRCS 			= ./srcs
DIR_HOME 			= $(HOME)
DIR_SECRET 			= $(DIR_HOME)/.secrets
DIR_DATA 			= $(DIR_HOME)/data
DIR_DATA_WP 		= $(DIR_DATA)/wordpress
DIR_DATA_DB 		= $(DIR_DATA)/mariadb
DC 					= DOCKER_BUILDKIT=0 docker compose -f $(DIR_SRCS)/docker-compose.yml -f $(DIR_SRCS)/docker-compose.override.yml
APP_VERSION 		= 0.0.1
OS 					= alpine
OS_VERSION 			= 3.19
VOLUME_WP 			= wp-files
VOLUME_DB 			= db-data
NETWORK 			= inception-network
SERVICES 			:= nginx db wordpress

default: run

.PHONY: run
run: build .setup-hosts
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

.PHONY: build
build: .build-base .init-env
	@echo "$(BLUE)Checking other images...$(RESET)"
	@for service in $(SERVICES); do \
		if docker image inspect inception/$$service:$(APP_VERSION) > /dev/null 2>&1; then \
			echo "$(GREEN)Image for $$service already exists.$(RESET)"; \
		else \
			echo "$(BLUE)Building image for $$service...$(RESET)"; \
			$(DC) build $$service --no-cache; \
		fi; \
	done
	@echo "$(GREEN)All necessary images are ready.$(RESET)"

.PHONY: re
re: clean run

.PHONY: re-service
re-service: .build-base
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE is not specified. Usage: make re-service SERVICE=<service_name>$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Rebuilding service: $(SERVICE)$(RESET)"
	@$(DC) stop $(SERVICE)
	@$(DC) rm -f $(SERVICE)
	@echo "$(YELLOW)Removing $(SERVICE) image...$(RESET)"
	@docker rmi inception/$(SERVICE):$(APP_VERSION) || true
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

.PHONY: clean
clean:
	@echo "$(YELLOW)Stopping and removing containers...$(RESET)"
	@$(DC) down
	@echo "$(RED)Removing all project images...$(RESET)"
	@docker rmi -f $(shell docker images "inception/*" -q) || true
	@echo "$(YELLOW)Removing dangling images...$(RESET)"
	@docker image prune -f
	@echo "$(GREEN)Image cleanup completed.$(RESET)"

.PHONY: fclean
fclean: clean
	@echo "$(YELLOW)Removing volumes and networks...$(RESET)"
	@docker volume rm $(VOLUME_WP) || true
	@docker volume rm $(VOLUME_DB) || true
	@docker network rm $(NETWORK) || true
	rm -f $(DIR_SRCS)/.env
	rm -f $(DIR_SRCS)/docker-compose.override.yml

.PHONY: logs
logs:
	@echo "$(CYAN)Showing logs...$(RESET)"
	@$(DC) logs -f

.PHONY: .build-base
.build-base: .check-create-volume .check-create-network .generate-override
	@echo "$(BLUE)Checking base image...$(RESET)"
	@if docker image inspect inception/base:$(APP_VERSION) > /dev/null 2>&1; then \
		echo "$(GREEN)Base image already exists: inception/base:$(APP_VERSION)$(RESET)"; \
	else \
		echo "$(BLUE)Building base image...$(RESET)"; \
		$(DC) build base --no-cache; \
		echo "$(GREEN)Base image has been built: inception/base:$(APP_VERSION)$(RESET)"; \
	fi

.PHONY: .check-create-volume
.check-create-volume:
	@echo "$(BLUE)Checking and creating volumes...$(RESET)"
	@for vol in $(VOLUME_WP) $(VOLUME_DB); do \
		if [ -z "$$(docker volume ls -q -f name=$$vol)" ]; then \
			echo "$(YELLOW)Docker volume $$vol does not exist. Creating...$(RESET)"; \
			docker volume create $$vol; \
		else \
			echo "$(GREEN)Docker volume $$vol already exists.$(RESET)"; \
		fi; \
	done

.PHONY: .check-create-network
.check-create-network:
	@echo "$(BLUE)Checking and creating networks...$(RESET)"
	@for net in $(NETWORK); do \
		if [ -z "$$(docker network ls -q -f name=$$net)" ]; then \
			echo "$(YELLOW)Docker network $$net does not exist. Creating...$(RESET)"; \
			docker network create $$net; \
		else \
			echo "$(GREEN)Docker network $$net already exists.$(RESET)"; \
		fi; \
	done

.PHONY: .init-env
.init-env:
	@echo "$(BLUE)Initializing environment variables...$(RESET)"
	$(eval USER_NAME=$(shell whoami))
	@echo "$(YELLOW)Creating .env file..."
	@echo "# $(DIR_SRCS)/.env" > $(DIR_SRCS)/.env
	@echo "# Basic setup" >> $(DIR_SRCS)/.env
	@echo "OS=$(OS)" >> $(DIR_SRCS)/.env
	@echo "OS_VERSION=$(OS_VERSION)" >> $(DIR_SRCS)/.env
	@echo "APP_VERSION=$(APP_VERSION)" >> $(DIR_SRCS)/.env
	@echo "DOMAIN_NAME=$(USER_NAME).42.fr" >> $(DIR_SRCS)/.env

	@echo "\n# Directory setup" >> $(DIR_SRCS)/.env
	@echo "DIR_HOME=$(DIR_HOME)" >> $(DIR_SRCS)/.env
	@echo "DIR_SECRET=$(DIR_SECRET)" >> $(DIR_SRCS)/.env
	@echo "DIR_DATA=$(DIR_DATA)" >> $(DIR_SRCS)/.env
	@echo "DIR_DATA_WP=$(DIR_DATA_WP)" >> $(DIR_SRCS)/.env
	@echo "DIR_DATA_DB=$(DIR_DATA_DB)" >> $(DIR_SRCS)/.env

	@echo "\n# DB setup" >> $(DIR_SRCS)/.env
	@echo "MYSQL_ROOT_PASSWORD=$(shell openssl rand -base64 12)" >> $(DIR_SRCS)/.env
	@echo "MYSQL_ADMIN=$(USER_NAME)" >> $(DIR_SRCS)/.env
	@echo "MYSQL_ADMIN_PASSWORD=$(shell openssl rand -base64 12)" >> $(DIR_SRCS)/.env
	@echo "MYSQL_ADMIN_EMAIL=$(USER_NAME)@42.fr" >> $(DIR_SRCS)/.env
	@echo "MYSQL_DATABASE=wordpress" >> $(DIR_SRCS)/.env
	@echo "MYSQL_USER=wordpress" >> $(DIR_SRCS)/.env
	@echo "MYSQL_USER_PASSWORD=$(shell openssl rand -base64 12)" >> $(DIR_SRCS)/.env
	@echo "MYSQL_USER_EMAIL=wordpress@42.fr" >> $(DIR_SRCS)/.env
	
	@echo "\n# Docker-compose setup" >> $(DIR_SRCS)/.env
	@echo "VOLUME_WP=$(VOLUME_WP)" >> $(DIR_SRCS)/.env
	@echo "VOLUME_DB=$(VOLUME_DB)" >> $(DIR_SRCS)/.env
	@echo "NETWORK=$(NETWORK)" >> $(DIR_SRCS)/.env

	@echo "$(GREEN).env file has been created.$(RESET)"

.PHONY: .generate-override
.generate-override:
	@echo "$(BLUE)Generating docker-compose.override.yml...$(RESET)"
	@sed -e 's#NETWORK_PLACEHOLDER#$(NETWORK)#g' \
		-e 's#VOLUME_WP_PLACEHOLDER#$(VOLUME_WP)#g' \
		-e 's#VOLUME_DB_PLACEHOLDER#$(VOLUME_DB)#g' \
		$(DIR_SRCS)/docker-compose.override.yml.template > $(DIR_SRCS)/docker-compose.override.yml
	@echo "$(GREEN)docker-compose.override.yml has been generated.$(RESET)"

.PHONY: .setup-hosts
.setup-hosts:
	@echo "$(BLUE)Setting up /etc/hosts...$(RESET)"
	@if grep -q "$(USER_NAME).42.fr" /etc/hosts; then \
		echo "$(GREEN)Host entry already exists.$(RESET)"; \
	else \
		echo "$(YELLOW)Adding host entry...$(RESET)"; \
		echo "127.0.0.1 $(USER_NAME).42.fr" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)Host entry added successfully.$(RESET)"; \
	fi

.PHONY: help
help:
	@echo "$(CYAN)Available targets:$(RESET)"
	@echo "  $(YELLOW)build$(RESET)			- Build Docker images"
	@echo "  $(YELLOW)run$(RESET)			- Build and start services"
	@echo "  $(YELLOW)clean$(RESET)			- Stop and remove containers, volumes, and networks"
	@echo "  $(YELLOW)re$(RESET)			- Rebuild and restart services"
	@echo "  $(YELLOW)re-service$(RESET)	- Rebuild and restart a specific service. Usage: make re-service SERVICE=<service_name>"
	@echo "  $(YELLOW)fclean$(RESET)		- Perform clean and remove all project images"
	@echo "  $(YELLOW)logs$(RESET)			- Show service logs"

