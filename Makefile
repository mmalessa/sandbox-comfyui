DC = docker compose
APP = comfyui
SH = bash

.DEFAULT_GOAL      = help

.PHONY: help
help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

.PHONY: nv-check
nv-check: ## Check if nvidia-container-toolkit is installed
	@if dpkg -s nvidia-container-toolkit > /dev/null 2>&1; then \
		echo "nvidia-container-toolkit is installed"; \
	else \
		echo "nvidia-container-toolkit is NOT installed. Run: make nv-prepare"; \
		exit 1; \
	fi

.PHONY: nv-prepare
nv-prepare: ## Install nvidia-container-toolkit and configure Docker runtime
	sudo apt install -y wget
	wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
	sudo dpkg -i cuda-keyring_1.1-1_all.deb
	sudo apt update
	sudo apt install -y nvidia-container-toolkit
	sudo nvidia-ctk runtime configure --runtime=docker
	echo 'Now restart docker: sudo systemctl restart docker'

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
