#!/bin/bash

cd $DOCKER_APP_DEST;
alembic upgrade head;
