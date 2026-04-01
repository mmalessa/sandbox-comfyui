DC = docker compose
APP = comfyui
SH = bash

.DEFAULT_GOAL      = help

.PHONY: help
help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

.PHONY: build
build:
	@$(DC) build

### DEV
.PHONY: up
up: ## Start the project docker containers
	@$(DC) up -d

.PHONY: down
down: ## Down the docker containers
	@$(DC) down --timeout 25

.PHONY: sh
sh: ## Open a shell in the running container
	@$(DC) exec -it $(APP) $(SH)

.PHONY: logs
logs: ## View the logs of the docker containers
	@$(DC) logs -f $(APP)

.PHONY: init
init:
	chmod +x ./init-models.sh
	./init-models.sh
