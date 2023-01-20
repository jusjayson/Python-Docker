# Python-Docker
For those who head-bash anxiously upon the thought of deploying/developing in docker.

<br/>

## Goal
A user should be able to start a python repo (or clone a pre-existing one), specify a handful of variables, and easily build/launch their project atop a Python version of choice.

<br/>

## Constraints
Currently, Python-Docker is intended for use on linux platforms, specifically via the poetry package manager. These constraints are chosen based on opinionated convenience, and are open for expansion (for anyone willing to volunteer development time).

<br/>

## But why do I need this?
### Is configuring a bunch of variables really any easier than just doing this on my own?
The project aims to set reasonable defaults, such that most configuration is for individuality, rather than necessity. As such, so long as your individuality is consistent, you should be able to "put the work in" once and simply copy env files from project to project afterwards.

<br/>

### What if I have a team that needs to use the same repo?
For teams, non-confidential variable configurations can be saved to version control, so that subsequent members need only to pull the project repo, specify any secrets according to team guidelines, and deploy their intended project.

<br/>

### My project has (private) dependencies it needs to pull from git. How does Python-Docker handle this?
By default, Python-Docker uses the current user's ssh info as follows:
- known_hosts from the $HOME/.ssh directory of the current user are used in ``ssh-keyscan -t rsa github/gitlab.com`` to allow pulling from private repos. 
- to avoid exposing private data in builds, Python-Docker makes use of docker's ``--mount=type=ssh`` to forward the existing SSH agent connection/key

<br/>

## Getting started

<br/>

### Prerequisites
Python-Docker is meant to be called indirectly via make commands (specifically, from a Makefile in your project's root). As such, copy the content of ``examples/Project-Makefile`` into a Makefile in your project's root. None of the included variables need be modified, as they can all be overriden (as directed in the ``Configuring variables`` section below).

<br/>

#### Pre-existing files
In order to streamline project configuration, the following assumptions are made:
- The project contains a config folder with ``logging.conf`` file specifying loggers (with, at minimum, a root logger configured. See ``examples/logging.conf``)
- The user specifies one to two env files (one for common usage across namespaces, and one specific to the current namespace). Python-Docker includes examples in ``examples/docker/env``. If no env files are specified, those variables defined in ``Variables intended for env files`` must be specified before each make command.
- The project contains ``pyproject.toml`` and ``poetry.lock`` files (in the root directory) in order to pull project dependencies via poetry and install the project (See ``examples/pyproject.toml``)
- The project includes a ``README.md`` file in the project root.

<br/>

### Build your python version's base image
The essence of Python-Docker is to build your intended python project atop the docker/python (``https://hub.docker.com/_/python/``) base image. As such, the first command you should run (from your project root) is ``PYTHON_VERSION={VERSION_NUMBER} make build-base-image``, with VERSION_NUMBER in the form of MAJOR.MINOR (in example, 3.10). This step is unnecessary if a pre-existing base image already exists at the address provided by the DOCKER_REGISTRY var (see ``Configuring variables`` section).

<br/>

### Build project
From your project's root, run ``make build-project``

<br/>

### Deploy project
In order to deploy your project with some entrypoint meant to run the project automatically (see ``DOCKER_ENTRYPOINT_SOURCE_FROM_CTX`` in ``Variables intended for env files``), run ``make deploy-project`` from your project root.

<br/>

### Launch local container
To do local project development, run ``make launch-local-project`` from your project root. 

<br/>

### Teardown project
To teardown containers, run ``make teardown-project`` from your project root
- Note: This will teardown any running containers matching the services in the compose file at {DOCKER_COMPOSE_FILE}(defaulting to {DOCKER_CTX_FROM_PYTHON_DOCKER}/{DOCKER_PROJECT_ROOT_FROM_CTX}/config/docker-compose.{NAMESPACE}.yaml), as well as any orphaned containers.

<br/>

## Configuring variables
Python-Docker uses a combination of environmental var files (see ``Environmental variables to proceed make commands`` below) along with reasonable defaults to minimize project configuration.

<br/>

### Environmental variables to proceed make commands
The following path file variables (used to override default variables and provide variables to which there is no reasonable default) may be included before all make commands:
- ``DOCKER_COMMON_ENV_PATH`` Path to namespace (e.g., production, staging, local) agnostic env vars
- ``DOCKER_SPECIFIC_ENV_PATH``: Path to namespace (e.g., production, staging, local) specific env vars

<br/>

### Variables intended for env files
- ``DOCKER_CTX_FROM_COMPOSE``: Path to docker's context from your docker compose file (compose files are conventionally pathed as {PROJECT_ROOT}/{DOCKER_PROJECT_ROOT_FROM_CTX}/config/docker/compose/docker-compose.{NAMESPACE}.yaml, but this is specificable via ``DOCKER_COMPOSE_FILE``)
- ``DOCKER_CTX_FROM_PROJECT_ROOT``: Path from project root to the docker ctx (necessary to access python docker)
- ``DOCKER_CTX_FROM_PYTHON_DOCKER``: Path from python docker to the docker ctx (necessary to access your project's source and any config you'd like to keep outside of the project's repo)
- ``DOCKER_ENTRYPOINT_SOURCE_FROM_CTX `` (relevant for building projects): Path to entrypoint file (for the provided namespace) used by container upon launch (entrypoint files are conventionally pathed as {PROJECT_ROOT}/{DOCKER_PROJECT_ROOT_FROM_CTX}/config/docker/scripts/{NAMESPACE}-entrypoint.sh)
- ``DOCKER_PROJECT_ROOT_FROM_CTX``: Reverse of ``DOCKER_CTX_FROM_PROJECT_ROOT``
- ``DOCKER_PYTHON_DOCKER_FROM_CTX``: Reverse of ``DOCKER_CTX_FROM_PYTHON_DOCKER``
- ``DOCKER_REGISTRY``: Address (local if no actual docker repo exists) to push/pull images
- ``NAMESPACE`` (i.e., local, staging, production): Used to locate conventionally placed compose and entrypoint files, name images and containers, and determine which type of Dockerfile to use when building project images.
- ``PROJECT_NAME``: Used to uniquely name images, containers, and accompanying services (like postgres and rabbitmq)
- ``PYTHON_VERSION`` (defaults to version ``3.10``): Which python version to use when building base image and project

<br/>

### Advanced variables
- ``DOCKER_APP_DEST``: Root directory for application in the deployed docker container
- ``DOCKER_ENTRYPOINT_DEST``: Path (in deployed docker container) to entrypoint script
- ``DOCKER_LOCAL_COMMAND``: Command run on start of docker container when running ``make launch-local-project``
- ``DOCKER_NO_CACHE`` (relevant for building projects): If defined, docker will not use its pre-existing cache (if any) while building the intended project
- ``DOCKER_TAG_VERSION`` (defaults to latest): Which version of the relevant image to pull (i.e., Python base image or project). In the case of the former, this variable should be passed as an environmental variable, i.e.: ``DOCKER_TAG_VERSION=1.2 make build-base-image``
- ``DOCKER_USER_CONFIG_PATH_FROM_CTX``: Path to config folder to be passed into project's docker container (conventionally pathed at {PROJECT_ROOT}/{config})
- ``DOCKER_WATCH`` (relevant to deploy-project):  If defined (by default, it isn't), the container will be deployed without ``-d`` option (such that the container does not run in the background)

<br/>


# What if I need other services besides my project?
Often, local development on a project will require access to services such as a messaging queue, database, frontend, etc. You'll find additional sample compose, env, and script files for such services in ``examples/docker/``. Build configurations for such services are out of the scope of this project.


