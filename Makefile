DOCKER_APP_DEST ?=
DOCKER_CTX ?= .
DOCKER_ENTRYPOINT_DEST ?= /app
DOCKER_ENTRYPOINT_SOURCE ?=
DOCKER_ENV_FILE ?= .env
NAMESPACE ?=
DOCKER_REGISTRY ?=
DOCKER_TAG_VERSION ?= latest

DOCKER_BASE_IMG ?= $(DOCKER_REGISTRY)/python-docker/base:latest

include $(ENV_FILE)
export

build-base-image:
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build -t $(DOCKER_REGISTRY)/python-docker/base:$(DOCKER_TAG_VERSION) -f DockerFile/Dockerfile.base .

build-project:
	DOCKER_BUILDKIT=1 docker build \
		--build-arg APP_DEST=$(DOCKER_APP_DEST) \
		--build-arg BASE_IMG=$(DOCKER_BASE_IMG) \
		--build-arg NAMESPACE=$(NAMESPACE) \
		--build-arg ENTRYPOINT_SOURCE=$(DOCKER_ENTRYPOINT_SOURCE) \
		--build-arg ENTRYPOINT_DEST=$(DOCKER_ENTRYPOINT_DEST) \
		-t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(NAMESPACE):$(DOCKER_TAG_VERSION) \
		--ssh default=$(HOME)/.ssh/id_rsa \
		-f ./DockerFile/Dockerfile.$(NAMESPACE)\
	$(DOCKER_CTX)
