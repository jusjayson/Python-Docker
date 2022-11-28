
include $(DOCKER_COMMON_ENV_FILE)
include $(DOCKER_SPECIFIC_ENV_FILE)
export

DOCKER_APP_DEST ?=
DOCKER_APP_SOURCE ?=
DOCKER_COMMON_ENV_FILE ?= base.env
DOCKER_CTX ?= .
DOCKER_ENTRYPOINT_DEST ?= /entrypoint.sh
DOCKER_ENTRYPOINT_SOURCE ?=
DOCKER_REGISTRY ?=
DOCKER_TAG_VERSION ?= latest
NAMESPACE ?=
PROJECT_ROOT ?=
ifndef DOCKER_WATCH
DOCKER_NO_WATCH = -d
endif

DOCKER_BASE_IMG ?= $(DOCKER_REGISTRY)/python-docker/base:latest
DOCKER_COMPOSE_FILE ?= $(PROJECT_ROOT)/src/config/docker/compose/docker-compose.$(NAMESPACE).yaml
DOCKER_SPECIFIC_ENV_FILE ?= $(NAMESPACE).env

build-base-image:
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build \
		-t $(DOCKER_REGISTRY)/python-docker/base:$(DOCKER_TAG_VERSION) \
		-f DockerFile/Dockerfile.base .

build-project:
	DOCKER_BUILDKIT=1 docker build \
		--build-arg APP_DEST=$(DOCKER_APP_DEST) \
		--build-arg APP_SOURCE=$(DOCKER_APP_SOURCE) \
		--build-arg BASE_IMG=$(DOCKER_BASE_IMG) \
		--build-arg NAMESPACE=$(NAMESPACE) \
		--build-arg ENTRYPOINT_SOURCE=$(DOCKER_ENTRYPOINT_SOURCE) \
		--build-arg ENTRYPOINT_DEST=$(DOCKER_ENTRYPOINT_DEST) \
		-t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(NAMESPACE):$(DOCKER_TAG_VERSION) \
		--ssh default=$(HOME)/.ssh/id_rsa \
		-f ./DockerFile/Dockerfile.$(NAMESPACE) \
		--progress=plain \
	$(DOCKER_CTX)

deploy-project:
	docker compose -f $(DOCKER_COMPOSE_FILE) up $(DOCKER_NO_WATCH)

teardown-project:
	docker compose -f $(DOCKER_COMPOSE_FILE) down
