# NOTE: This specified docker environmental variables are not exhaustive,
# and are restricted to those base variables intended for use in every project.

ifdef DOCKER_COMMON_ENV_PATH
include $(DOCKER_COMMON_ENV_PATH)
endif

ifdef DOCKER_SPECIFIC_ENV_PATH
include $(DOCKER_SPECIFIC_ENV_PATH)
endif
export

DOCKER_APP_DEST ?= /app
DOCKER_APP_SOURCE_FROM_CTX ?=
DOCKER_CTX_FROM_PYTHON_DOCKER ?= ..
DOCKER_NO_WATCH ?=
DOCKER_PROJECT_ROOT_FROM_CTX ?=
DOCKER_ENTRYPOINT_DEST ?= /entrypoint.sh
DOCKER_REGISTRY ?=
DOCKER_TAG_VERSION ?= latest
NAMESPACE ?=
PROJECT_NAME ?=
PYTHON_VERSION ?= 3.10

DOCKER_BASE_IMG ?= $(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:latest
DOCKER_COMPOSE_FILE ?= $(DOCKER_CTX_FROM_PYTHON_DOCKER)/$(DOCKER_PROJECT_ROOT_FROM_CTX)/src/config/docker/compose/docker-compose.$(NAMESPACE).yaml
DOCKER_ENTRYPOINT_SOURCE ?= $(DOCKER_CTX_FROM_PYTHON_DOCKER)/$(DOCKER_PROJECT_ROOT_FROM_CTX)/src/config/docker/scripts/$(NAMESPACE)-entrypoint.sh

build-base-image:
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build \
		-t $(DOCKER_REGISTRY)/python-docker/$(PYTHON_VERSION)/base:$(DOCKER_TAG_VERSION) \
		-f DockerFile/Dockerfile.base.$(PYTHON_VERSION) .

build-project:
	DOCKER_BUILDKIT=1 docker build \
		--build-arg APP_DEST=$(DOCKER_APP_DEST) \
		--build-arg APP_SOURCE_FROM_CTX=$(DOCKER_APP_SOURCE_FROM_CTX) \
		--build-arg BASE_IMG=$(DOCKER_BASE_IMG) \
		--build-arg NAMESPACE=$(NAMESPACE) \
		--build-arg ENTRYPOINT_SOURCE=$(DOCKER_ENTRYPOINT_SOURCE) \
		--build-arg ENTRYPOINT_DEST=$(DOCKER_ENTRYPOINT_DEST) \
		-t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(NAMESPACE):$(DOCKER_TAG_VERSION) \
		--ssh default=$(HOME)/.ssh/id_rsa \
		-f ./DockerFile/Dockerfile.$(NAMESPACE) \
		--progress=plain \
	$(DOCKER_CTX_FROM_PYTHON_DOCKER)

deploy-project:
	DOCKER_APP_DEST=$(DOCKER_APP_DEST) \
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
	DOCKER_TAG_VERSION=$(DOCKER_TAG_VERSION) \
	NAMESPACE=$(NAMESPACE) \
	PROJECT_NAME=$(PROJECT_NAME) \
		docker compose -f $(DOCKER_COMPOSE_FILE) up $(DOCKER_NO_WATCH)

		
teardown-project:
	docker compose -f $(DOCKER_COMPOSE_FILE) down --remove-orphans
