#
#  Copyright 2024 F5 Networks
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

.DEFAULT_GOAL := help

PACKAGE_ROOT  := github.com/F5ObservabilityHub
PACKAGE       := $(PACKAGE_ROOT)/AppFramework
DATE          ?= $(shell date -u +%FT%T%z)
VERSION       ?= $(shell cat $(CURDIR)/.version 2> /dev/null || echo 0.0.0)
GITHASH       ?= $(shell git rev-parse HEAD)

SED           ?= $(shell which gsed 2> /dev/null || which sed 2> /dev/null)
GREP          ?= $(shell which ggrep 2> /dev/null || which grep 2> /dev/null)
ARCH          := $(shell uname -m | $(SED) -e 's/x86_64/amd64/g' -e 's/i686/i386/g')
PLATFORM      := $(shell uname | tr '[:upper:]' '[:lower:]')
SHELL         := bash

TIMEOUT = 45
V = 0
Q = $(if $(filter 1,$V),,@)
M = $(shell printf "\033[34;1m▶\033[0m")

#include container tool environment variables
include $(dir $(lastword $(MAKEFILE_LIST)))/Makefile.containers

DOCKER_COMPOSE_FILE := $(firstword $(wildcard $(CURDIR)/docker-compose.yaml $(CURDIR)/compose.yaml))

# Check if a Docker Compose file was found
ifeq ($(DOCKER_COMPOSE_FILE),)
$(warning No valid Docker Compose file found (docker-compose.yaml or compose.yaml), set with 'make DOCKER_COMPOSE_FILE=<path> ...' or move to the directory with the main Makefile)
endif

.PHONY: check-appframework
check-appframework: # Ensure this submodule is initialized (hidden from help)

.PHONY: up
up: ## Docker compose up
	@echo "🚀 Starting the Docker Compose environment..."
	@echo "Starting in foreground mode..."
	@trap 'exit 0' INT; $(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) up  || true

.PHONY: start
start: ## Runs docker compose up -d
	@echo "🚀 Starting the Docker Compose environment..."
	@echo "🚀 Health checks have to pass before this command completes (be patient)..."
	@echo "Starting in daemon mode..."
	@$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) up -d;

.PHONY: ps
ps: ## Runs docker compose ps
	@echo "🚀 Starting the Docker Compose environment..."
	@$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) ps;

.PHONY: down
down: ## Runs docker compose down
	@echo "🛑 Stopping the Docker Compose environment..."
	@$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) down;

.PHONY: stop
stop: down ## Alias for down
	@echo "🛑 Docker Compose environment stopped."

.PHONY: logs
logs: ## Runs docker compose logs --tail 100 -f
	@echo "📄 Viewing Docker Compose logs..."
	@trap 'exit 0' INT; $(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) logs --tail 100 -f || true

.PHONY: logs-% 
logs-%: ## Runs docker compose logs <for the specified container> --tail 100 -f
	@echo "📄 Viewing Docker Compose logs for $* Container..."
	@trap 'exit 0' INT; $(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) logs $* --tail 100 -f || true

.PHONY: restart-% 
restart-%: ## Runs docker compose restart <for the specified container>
	@echo "🔄 Restarting container: $*..."
	@$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) restart $*

.PHONY: exec-%
exec-%: ## Executes a shell inside the specified container
	@if [ "$*" = "otel-collector" ]; then \
		echo "⚠️ Warning: The 'otel-collector' container does not include a shell."; \
		exit 0; \
	else \
		echo "🚀 Executing shell in $* container..."; \
		$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) exec -it $* /bin/sh; \
	fi

.PHONY: destroy
destroy: ## Docker compose down and remove volumes, destroying all data
	@echo "🚩🚩🚩 Destroying compose environment and removing volumes. 🚩🚩🚩"
	@read -p "Continue? [y/N]: " line; \
	if [ "$$line" != "Y" ] && [ "$$line" != "y" ]; then \
		echo "Aborting..."; \
		exit 0; \
	fi; \
	$(CONTAINER_COMPOSETOOL) -f $(DOCKER_COMPOSE_FILE) down -v;

.PHONY: observability-dev-up
observability-dev-up: # Docker compose up for observability development stack
	@echo "🚀 Starting the Local Dev Default Docker Compose environment..."
	@echo "Starting in foreground mode..."
	@trap 'exit 0' INT; $(CONTAINER_COMPOSETOOL) -f stacks/observability-development/compose.yaml up || true;

.PHONY: observability-dev-start
observability-dev-start: # Docker compose up for observability development stack (detached mode)
	@echo "🚀 Starting the Local Dev Default Docker Compose environment..."
	@echo "Starting in detached mode..."
	@$(CONTAINER_COMPOSETOOL) -f stacks/observability-development/compose.yaml up -d;

.PHONY: observability-app-up
observability-app-up: # Docker compose up for Observability App stack
	@echo "🚀 Starting the  Observability App Default Docker Compose environment..."
	@echo "Starting in foreground mode..."
	@trap 'exit 0' INT; $(CONTAINER_COMPOSETOOL) -f stacks/observability-app/compose.yaml up || true;

.PHONY: observability-app-start
observability-app-start: # Docker compose up for Observability App stack (detached mode)
	@echo "🚀 Starting the Observability App Default Docker Compose environment..."
	@echo "Starting in detached mode..."
	@$(CONTAINER_COMPOSETOOL) -f stacks/observability-app/compose.yaml up -d;

.PHONY: test-observability-dev
test-observability-dev:
	@echo "Running tests with observability-development solution stack..."
	@./run_tests.sh ./stacks/observability-development/compose.test.yaml

.PHONY: test-observability-app
test-observability-app:
	@echo "Running integration tests with observability-app solution stack..."
	@./run_tests.sh ./stacks/observability-app/compose.test.yaml

.PHONY: test-all
test-all: test-observability-dev test-observability-app
	@echo "All tests completed."