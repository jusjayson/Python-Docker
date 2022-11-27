DOCKER_TAG_VERSION ?= latest

import-env-files:
	set -a
	. ./Env/base.env
	set +a

build-base-image: import-env-files
	DOCKER_BUILDKIT=1 PROJECT_NAME=python-docker docker build --build-arg -t $(DOCKER_REGISTRY)/python-docker/base:$(DOCKER_TAG_VERSION) DockerFile/Dockerfile.base .

build-project:
	DOCKER_BUILDKIT=1 docker build --build-arg -t $(DOCKER_REGISTRY)/$(PROJECT_NAME)/$(DOCKER_NAMESPACE):$(DOCKER_TAG_VERSION) --ssh default=$(HOME)/.ssh/id_rsa -f DockerFile/Dockerfile.$(DOCKER_NAMESPACE) .