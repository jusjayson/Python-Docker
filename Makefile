# NOTE: This specified docker environmental variables are not exhaustive,
# and are restricted to those base variables intended for use in every project.

DOCKER_APP_DEST ?= /app
DOCKER_CONFIG_FOLDER_PATH ?= /root/.$(PROJECT_NAME)/config
DOCKER_CTX_FROM_COMPOSE ?= ../../../..
DOCKER_CTX_FROM_PYTHON_DOCKER ?= ..
DOCKER_PROJECT_ROOT_FROM_CTX ?=
DOCKER_ENTRYPOINT_DEST ?= /entrypoint.sh
DOCKER_REGISTRY ?=
DOCKER_TAG_VERSION ?= latest
DOCKER_USER_CONFIG_PATH_FROM_CTX ?=
DOCKER_USER_LOCAL_LOG_PATH_FROM_CTX ?= $(DOCKER_PROJECT_ROOT_FROM_CTX)/logs
DONT_PASS_SSH_KEYS ?= 

ifdef DOCKER_NO_CACHE
	DOCKER_CACHE_OPTION = --no-cache
endif

ifndef DOCKER_WATCH
DOCKER_NO_WATCH = -d
endif

ifndef DONT_PASS_SSH_KEYS
	SSH_OPTION = --ssh default=$(HOME)/.ssh/id_rsa
endif

DOCKER_APP_SOURCE_FROM_COMPOSE ?= $(DOCKER_CTX_FROM_COMPOSE)/$(DOCKER_PROJECT_ROOT_FROM_CTX)
DOCKER_BASE_IMG ?= $(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:$(DOCKER_TAG_VERSION)
DOCKER_COMPOSE_FILE ?= $(DOCKER_CTX_FROM_PYTHON_DOCKER)/$(DOCKER_PROJECT_ROOT_FROM_CTX)/config/docker/compose/docker-compose.$(NAMESPACE).yaml
DOCKER_ENTRYPOINT_SOURCE_FROM_CTX ?= $(DOCKER_CTX_FROM_PYTHON_DOCKER)/$(DOCKER_PROJECT_ROOT_FROM_CTX)/config/docker/scripts/$(NAMESPACE)-entrypoint.sh

NAMESPACE ?=
PROJECT_NAME ?=
PYTHON_VERSION ?= 3.10

build-base-image:
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build \
		-t $(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:$(DOCKER_TAG_VERSION) \
		-f ./config/docker/build/Dockerfile.base.$(PYTHON_VERSION) .

init-project:
	docker run \
		-v $(DOCKER_ABSOLUTE_APP_SOURCE):/app \
		--name init-project \
		-it \
		$(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:$(DOCKER_TAG_VERSION) \
		bash -c "cd /app && poetry init && poetry install --no-root" && \
	docker rm init-project && \
	sudo chown -R $(USER) $(DOCKER_ABSOLUTE_APP_SOURCE)/pyproject.toml && \
	sudo chown -R $(USER) $(DOCKER_ABSOLUTE_APP_SOURCE)/poetry.lock

update-project:
	docker run \
		-v $(DOCKER_ABSOLUTE_APP_SOURCE):/app \
		--name update-project \
		-it \
		$(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:$(DOCKER_TAG_VERSION) \
		bash -c "cd /app && poetry update" && \
	docker rm update-project
	

build-project:
	DOCKER_BUILDKIT=1 docker build \
		--build-arg APP_DEST=$(DOCKER_APP_DEST) \
		--build-arg APP_SOURCE_FROM_CTX=$(DOCKER_PROJECT_ROOT_FROM_CTX) \
		--build-arg BASE_IMG=$(DOCKER_BASE_IMG) \
		--build-arg CONFIG_FOLDER_PATH=$(DOCKER_CONFIG_FOLDER_PATH) \
		--build-arg ENTRYPOINT_DEST=$(DOCKER_ENTRYPOINT_DEST) \
		--build-arg ENTRYPOINT_SOURCE=$(DOCKER_ENTRYPOINT_SOURCE_FROM_CTX) \
		--build-arg LOG_FOLDER_PATH=$(DOCKER_LOG_FOLDER_PATH) \
		--build-arg NAMESPACE=$(NAMESPACE) \
		--build-arg USER_CONFIG_PATH_FROM_CTX=$(DOCKER_USER_CONFIG_PATH_FROM_CTX) \
		-t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(NAMESPACE):$(DOCKER_TAG_VERSION) \
		$(SSH_OPTION) \
		-f ./config/docker/build/Dockerfile.$(NAMESPACE) \
		--progress=plain \
		$(DOCKER_CACHE_OPTION) \
	$(DOCKER_CTX_FROM_PYTHON_DOCKER)

deploy-project:
	DOCKER_APP_DEST=$(DOCKER_APP_DEST) \
	DOCKER_APP_SOURCE_FROM_COMPOSE=$(DOCKER_APP_SOURCE_FROM_COMPOSE) \
	DOCKER_CTX_FROM_COMPOSE=$(DOCKER_CTX_FROM_COMPOSE) \
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
	DOCKER_TAG_VERSION=$(DOCKER_TAG_VERSION) \
	DOCKER_USER_CONFIG_PATH_FROM_CTX=${DOCKER_USER_CONFIG_PATH_FROM_CTX} \
	DOCKER_USER_LOCAL_LOG_PATH_FROM_CTX=${DOCKER_USER_LOCAL_LOG_PATH_FROM_CTX} \
	NAMESPACE=$(NAMESPACE) \
	PROJECT_NAME=$(PROJECT_NAME) \
		docker compose -f $(DOCKER_COMPOSE_FILE) up $(DOCKER_NO_WATCH)

		
teardown-project:
	docker compose -f $(DOCKER_COMPOSE_FILE) down --remove-orphans
