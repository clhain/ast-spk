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

PACKAGE_ROOT  := github.com/nginxinc
PACKAGE       := $(PACKAGE_ROOT)/nginx-ai-gateway/gateway
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

AF_MAKEFILE := "AppFramework/Makefile"

# Conditionally include the AppFramework Makefile
-include $(wildcard AppFramework/Makefile)

# Default target when no other target is provided
.DEFAULT: # Print submodule warning message
	@echo "🚩Command not found.🚩"
	@echo "Please run ❗ 'make init' ❗ to initialize the submodule first."
	@exit 1

.PHONY: help
help: ## Show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\033[36m\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: init-submodule
init-submodule: # Initialize the AppFramework submodule and env files (hidden from help)
	@echo "🔄 Initializing Git submodule..."
	@git submodule init
	@git submodule update
	@echo "✅ Submodule initialized and updated."

.PHONY: init-project
init-project: ## Initialize the project files (hidden from help)
	@echo "📄 Initializing project files..."
	@find ./.init/project -type f | while read src; do \
		dest=$${src/.init\/project\//}; \
		dest_dir=$$(dirname $$dest); \
		mkdir -p $$dest_dir; \
		echo "📄 Copying $$src to $$dest..."; \
		if [ ! -f $$dest ]; then \
			cp -rn $$src $$dest; \
			echo "  ✅ $$dest file created."; \
		else \
			echo "  ⚠️  $$dest already exists. Skipping copy."; \
		fi \
	done

.PHONY: init
init: init-submodule init-project ## Initialize the Application Study Tool

.PHONY: upgrade-appframework
upgrade-appframework: # (🚩end users shouldn't run this🚩) Upgrade the AppFramework submodule
	@echo "🚩🚩🚩Upgrading the AppFramework submodule. You shouldn't do this unless you're a maintainer of this project...🚩🚩🚩"
	@read -p "Continue? [y/N]: " line; \
	if [ "$$line" != "Y" ] && [ "$$line" != "y" ]; then \
		echo "Aborting..."; \
		exit 0; \
	fi; \
	echo "🔄 Updating Git submodule from remote (strategy=merge)..."; \
	if ! git submodule update --remote --merge; then \
		echo "❌ Submodule update failed."; \
		exit 1; \
	else \
		echo "✅ Submodule upgraded."; \
	fi

.PHONY: upgrade
upgrade: ## Upgrade the local project to a new version
	@if [ -z "$(RELEASE_VERSION)" ]; then \
		echo "Error: RELEASE_VERSION is not specified."; \
		exit 1; \
	fi
	@git fetch --tags
	@if ! git rev-parse --verify tags/$(RELEASE_VERSION) >/dev/null 2>&1; then \
		echo "❌ Error: Tag '$(RELEASE_VERSION)' not found."; \
		exit 1; \
	fi
	@git pull origin main
	@git checkout tags/$(RELEASE_VERSION)

.PHONY: configure
configure: check-appframework ## Run the AST configuration helper script to generate otel configs.
	@if [ -z "$(CONTAINER_CLITOOL)" ]; then \
		echo "❌ Error: CONTAINER_CLITOOL environment variable is not set, you may need to run 'make init'"; \
		exit 1; \
	fi; \
	echo "🚀 Running AST Configuration helper via $(CONTAINER_CLITOOL)..."; \
	$(CONTAINER_CLITOOL) run --rm -it -w /app -v $(shell pwd):/app --entrypoint /app/src/bin/init_entrypoint.sh python:3.12.6-slim-bookworm --generate-config

