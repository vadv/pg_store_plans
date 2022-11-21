# pg_stat_plan/Makefile

SHELL=/usr/bin/env bash

MODULES = pg_store_plans

MODULE_big = pg_store_plans
OBJS = pg_store_plans.o pgsp_json.o pgsp_json_text.o pgsp_explain.o

EXTENSION = pg_store_plans

PG_VERSION := $(shell pg_config --version | sed "s/^PostgreSQL //" | sed "s/\.[0-9]*$$//")

DATA = pg_store_plans--1.5--1.6.sql pg_store_plans--1.6--1.7.sql pg_store_plans--1.7--1.8.sql \
		pg_store_plans--1.5.sql pg_store_plans--1.6.sql pg_store_plans--1.8.sql

REGRESS = store vadv
REGRESS_OPTS = --temp-config=regress.conf

ifndef PG_CONFIG
PG_CONFIG = pg_config
endif
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

TARSOURCES = Makefile *.c  *.h \
	pg_store_plans--*.sql \
	pg_store_plans.control \
	docs/* expected/*.out sql/*.sql \