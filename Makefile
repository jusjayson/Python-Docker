DOCKER_TAG_VERSION ?= latest
ENV_FILE ?= .env
DOCKER_CTX ?= .
DOCKER_REGISTRY ?=
DOCKER_NAMESPACE ?=
BASE_IMAGE ?= $(DOCKER_REGISTRY)/python-docker/base:latest

import-env-files:
	set -a
	. $(ENV_FILE)
	set +a

build-base-image: import-env-files
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build -t $(DOCKER_REGISTRY)/python-docker/base:$(DOCKER_TAG_VERSION) -f DockerFile/Dockerfile.base .

build-project:
	DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(DOCKER_NAMESPACE):$(DOCKER_TAG_VERSION) --ssh default=$(HOME)/.ssh/id_rsa -f ./DockerFile/Dockerfile.$(DOCKER_NAMESPACE) $(DOCKER_CTX)
