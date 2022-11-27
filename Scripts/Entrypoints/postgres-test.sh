#!/bin/bash

psql -v ON_ERROR_STOP=1 --username "$PG_USER" <<-EOSQL
	CREATE DATABASE $PG_TEST_NAME \
        with OWNER=$PG_USER;
EOSQL
