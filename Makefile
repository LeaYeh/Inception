RED					:= $(shell tput -Txterm setaf 1)
GREEN				:= $(shell tput -Txterm setaf 2)
YELLOW				:= $(shell tput -Txterm setaf 3)
BLUE				:= $(shell tput -Txterm setaf 4)
MAGENTA				:= $(shell tput -Txterm setaf 5)
CYAN				:= $(shell tput -Txterm setaf 6)
WHITE				:= $(shell tput -Txterm setaf 7)
RESET				:= $(shell tput -Txterm sgr0)

OS_TYPE := $(shell uname)
ifeq ($(OS_TYPE),Darwin)
  DOCKER_BUILDKIT := 0
else
  DOCKER_BUILDKIT := 1
endif

# Configuration
PROJECT_NAME		= inception
WORKSPACE			= .
USER_NAME			= $(shell whoami)
USER_UID			= $(shell id -u)
USER_GID			= $(shell id -g)
DIR_SRCS			= $(WORKSPACE)/srcs
DIR_HOME			= $(HOME)
DIR_SECRET 			= .secrets
DIR_DATA			= $(DIR_HOME)/data
DIR_DATA_WP			= $(DIR_DATA)/wordpress
DIR_DATA_DB			= $(DIR_DATA)/mariadb
# DC 					= DOCKER_BUILDKIT=0 docker compose -f $(DIR_SRCS)/docker-compose.yml -f $(DIR_SRCS)/docker-compose.override.yml
DC 					= DOCKER_BUILDKIT=${DOCKER_BUILDKIT} docker compose -p $(PROJECT_NAME) -f $(DIR_SRCS)/docker-compose.yml -f $(DIR_SRCS)/docker-compose.override.yml --env-file $(DIR_SRCS)/.env
APP_VERSION 		= 0.0.1
OS 					= alpine
OS_VERSION 			= 3.19
VOLUME_WP 			= wp-files
VOLUME_DB 			= db-data
NETWORK 			= network
SERVICES 			:= nginx db wordpress

default: up

.PHONY: up
up: init
	@echo "$(GREEN)Starting services...$(RESET)"
	@$(DC) up -d
	@echo "$(YELLOW)Waiting for services to start...$(RESET)"
	@sleep 5
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

.PHONY: down
down:
	@echo "$(YELLOW)Destory services...$(RESET)"
	@$(DC) down || true
	@echo "$(GREEN)Services have been stopped.$(RESET)"

.PHONY: build
build: init .build-base
	@echo "$(BLUE)Checking other images...$(RESET)"
	@for service in $(SERVICES); do \
		if docker image inspect inception-$$service:$(APP_VERSION) > /dev/null 2>&1; then \
			echo "$(GREEN)Image for $$service already exists.$(RESET)"; \
		else \
			echo "$(BLUE)Building image for $$service without cache...$(RESET)"; \
			$(DC) build $$service --no-cache; \
		fi; \
	done
	@echo "$(GREEN)All necessary images are ready.$(RESET)"

.PHONY: re
re: fclean build up

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
	@docker rmi inception-$(SERVICE):$(APP_VERSION) || true
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
clean: down
	@echo "$(RED)Removing all project images...$(RESET)"
	@for s in $(SERVICES); do \
		echo "Removing inception-$$s:$(APP_VERSION)"; \
		docker rmi inception-$$s:$(APP_VERSION) || true; \
	done
	@echo "$(YELLOW)Removing dangling images...$(RESET)"
	@docker image prune -f
	@echo "$(GREEN)Image cleanup completed.$(RESET)"

.PHONY: fclean
fclean: clean
	@echo "$(YELLOW)Removing volumes and networks...$(RESET)"
	@docker volume rm $(PROJECT_NAME)_$(VOLUME_WP) || true
	@docker volume rm $(PROJECT_NAME)_$(VOLUME_DB) || true
	@docker network rm $(PROJECT_NAME)_$(NETWORK) || true
	@rm -f $(DIR_SRCS)/.env || true
	rm -f $(DIR_SRCS)/docker-compose.override.yml || true
	sudo rm -rf $(DIR_DATA) || true
	@echo "$(GREEN)Volume and network cleanup completed.$(RESET)"
	rm -rf $(DIR_SRCS)/$(DIR_SECRET)
	@echo "$(GREEN)Secrets have been removed.$(RESET)"

.PHONY: logs
logs:
	@echo "$(CYAN)Showing logs...$(RESET)"
	@$(DC) logs -f

.PHONY: .build-base
# .build-base: .generate-override
.build-base:
	@echo "$(BLUE)Checking base image...$(RESET)"
	@if docker image inspect inception-base:$(APP_VERSION) > /dev/null 2>&1; then \
		echo "$(GREEN)Base image already exists: inception-base:$(APP_VERSION)$(RESET)"; \
	else \
		echo "$(BLUE)Building base image...$(RESET)"; \
		$(DC) build base --no-cache; \
		echo "$(GREEN)Base image has been built: inception-base:$(APP_VERSION)$(RESET)"; \
	fi

.PHONY: init
init: .setup-hosts .init-env .init-dir .init-secrets .generate-override
	@echo "$(GREEN)Initial success!$(RESET)"

.PHONY: .init-dir
.init-dir:
	@echo "$(YELLOW)Create Directory...$(RESET)"
	# @rm -rf $(DIR_DATA)
	@mkdir -p $(DIR_DATA_DB)
	@mkdir -p $(DIR_DATA_WP)

.PHONY: .init-env
.init-env:
	@if [ ! -e $(DIR_SRCS)/.env ]; then \
		echo "$(BLUE)Initializing environment variables...$(RESET)"; \
		mkdir -p $(DIR_SRCS); \
		USER_NAME=$$(whoami); \
		echo "$(YELLOW)Creating .env file..."; \
		echo "# $(DIR_SRCS)/.env" > $(DIR_SRCS)/.env; \
		echo "# Basic setup" >> $(DIR_SRCS)/.env; \
		echo "PROJECT_NAME=$(PROJECT_NAME)" >> $(DIR_SRCS)/.env; \
		echo "OS=$(OS)" >> $(DIR_SRCS)/.env; \
		echo "OS_VERSION=$(OS_VERSION)" >> $(DIR_SRCS)/.env; \
		echo "APP_VERSION=$(APP_VERSION)" >> $(DIR_SRCS)/.env; \
		echo "DOMAIN_NAME=$$USER_NAME.42.fr" >> $(DIR_SRCS)/.env; \
		echo "USER_UID=$(USER_UID)" >> $(DIR_SRCS)/.env; \
		echo "USER_GID=$(USER_GID)" >> $(DIR_SRCS)/.env; \
		echo "" >> $(DIR_SRCS)/.env; \
		echo "# Directory setup" >> $(DIR_SRCS)/.env; \
		echo "DIR_SECRET=$(DIR_SECRET)" >> $(DIR_SRCS)/.env; \
		echo "DIR_DATA_WP=$(DIR_DATA_WP)" >> $(DIR_SRCS)/.env; \
		echo "DIR_DATA_DB=$(DIR_DATA_DB)" >> $(DIR_SRCS)/.env; \
		echo "" >> $(DIR_SRCS)/.env; \
		echo "# DB setup" >> $(DIR_SRCS)/.env; \
		echo "DB_HOST=db" >> $(DIR_SRCS)/.env; \
		echo "MYSQL_ADMIN=$$USER_NAME" >> $(DIR_SRCS)/.env; \
		echo "WP_DATABASE=wordpress" >> $(DIR_SRCS)/.env; \
		echo "WP_ADMIN=wordpress" >> $(DIR_SRCS)/.env; \
		echo "WP_USER=bob" >> $(DIR_SRCS)/.env; \
		echo "" >> $(DIR_SRCS)/.env; \
		echo "# Compose setup" >> $(DIR_SRCS)/.env; \
		echo "NETWORK=$(NETWORK)" >> $(DIR_SRCS)/.env; \
		echo "$(GREEN).env file has been created.$(RESET)"; \
	else \
		echo "$(YELLOW).env already exists.$(RESET)"; \
	fi

.PHONY: .init-secrets
.init-secrets:
	@echo "$(YELLOW)Create secret directory...$(RESET)"
	@mkdir -p $(DIR_SRCS)/$(DIR_SECRET)
	@if [ ! -f $(DIR_SRCS)/$(DIR_SECRET)/db_root_password ]; then \
		echo "$(BLUE)Generating random DB root password (secret)...$(RESET)"; \
		openssl rand -base64 12 | tr -d '=+/\n' > $(DIR_SRCS)/$(DIR_SECRET)/db_root_password; \
		chmod 644 $(DIR_SRCS)/$(DIR_SECRET)/db_root_password; \
	else \
		echo "$(YELLOW)Secret file already exists: $(DIR_SRCS)/$(DIR_SECRET)/db_root_password$(RESET)"; \
	fi
	@if [ ! -f $(DIR_SRCS)/$(DIR_SECRET)/db_admin_password ]; then \
		echo "$(BLUE)Generating random DB admin password (secret)...$(RESET)"; \
		openssl rand -base64 12 | tr -d '=+/\n' > $(DIR_SRCS)/$(DIR_SECRET)/db_admin_password; \
		chmod 644 $(DIR_SRCS)/$(DIR_SECRET)/db_admin_password; \
	else \
		echo "$(YELLOW)Secret file already exists: $(DIR_SRCS)/$(DIR_SECRET)/db_admin_password$(RESET)"; \
	fi
	@if [ ! -f $(DIR_SRCS)/$(DIR_SECRET)/wp_admin_password ]; then \
		echo "$(BLUE)Generating random WordPress admin password (secret)...$(RESET)"; \
		openssl rand -base64 12 | tr -d '=+/\n' > $(DIR_SRCS)/$(DIR_SECRET)/wp_admin_password; \
		chmod 644 $(DIR_SRCS)/$(DIR_SECRET)/wp_admin_password; \
	else \
		echo "$(YELLOW)Secret file already exists: $(DIR_SRCS)/$(DIR_SECRET)/wp_admin_password$(RESET)"; \
	fi
	@if [ ! -f $(DIR_SRCS)/$(DIR_SECRET)/wp_user_password ]; then \
		echo "$(BLUE)Generating random WordPress user password (secret)...$(RESET)"; \
		openssl rand -base64 12 | tr -d '=+/\n' > $(DIR_SRCS)/$(DIR_SECRET)/wp_user_password; \
		chmod 644 $(DIR_SRCS)/$(DIR_SECRET)/wp_user_password; \
	else \
		echo "$(YELLOW)Secret file already exists: $(DIR_SRCS)/$(DIR_SECRET)/wp_user_password$(RESET)"; \
	fi

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
	@echo "$(YELLOW)Setting up /etc/hosts...$(RESET)"
	@if grep -q "$(USER_NAME).42.fr" /etc/hosts; then \
		echo "$(GREEN)Host entry already exists.$(RESET)"; \
	else \
		echo "$(YELLOW)Adding host entry...$(RESET)"; \
		echo "127.0.0.1 $(USER_NAME).42.fr" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)Host entry added successfully.$(RESET)"; \
	fi

.PHONY: help
help:
	@echo "  $(CYAN)Available targets:$(RESET)"
	@echo "  $(YELLOW)build$(RESET)			- Build Docker images"
	@echo "  $(YELLOW)up$(RESET)			- Build and start services"
	@echo "  $(YELLOW)down$(RESET)			- Stop services"
	@echo "  $(YELLOW)clean$(RESET)			- Stop and remove containers, volumes, and networks"
	@echo "  $(YELLOW)re$(RESET)			- Rebuild and restart services"
	@echo "  $(YELLOW)re-service$(RESET)	- Rebuild and restart a specific service. Usage: make re-service SERVICE=<service_name>"
	@echo "  $(YELLOW)fclean$(RESET)		- Perform clean and remove all project images"
	@echo "  $(YELLOW)logs$(RESET)			- Show service logs"

