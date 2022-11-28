
include $(COMMON_ENV_FILE)
include $(SPECIFIC_ENV_FILE)
export

DOCKER_APP_DEST ?=
DOCKER_APP_SOURCE ?=
DOCKER_CTX ?= .
DOCKER_ENTRYPOINT_DEST ?= /app
DOCKER_ENTRYPOINT_SOURCE ?=
COMMON_ENV_FILE ?= .env
SPECIFIC_ENV_FILE ?= .env
NAMESPACE ?=
DOCKER_REGISTRY ?=
DOCKER_TAG_VERSION ?= latest

DOCKER_BASE_IMG ?= $(DOCKER_REGISTRY)/python-docker/base:latest
DOCKER_COMPOSE_FILE ?= $(DOCKER_APP_SOURCE)/src/config/docker/compose/docker-compose-$(NAMESPACE).yaml
ifndef WATCH_DOCKER
WATCH_DOCKER = -d
endif

build-base-image:
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build -t $(DOCKER_REGISTRY)/python-docker/base:$(DOCKER_TAG_VERSION) -f DockerFile/Dockerfile.base .

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
	$(DOCKER_CTX)

deploy-project:
	docker compose -f $(DOCKER_COMPOSE_FILE) --env-file <(cat "$(COMMON_ENV_FILE)" "$(SPECIFIC_ENV_FILE")) up $(WATCH_DOCKER)
