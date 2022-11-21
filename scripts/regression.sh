#!/usr/bin/env bash

set -ex

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y curl ca-certificates gnupg lsb-release build-essential
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt update

export PGUSER=postgres
export PGDATABASE=postgres
export PGPORT=7432
export PGVERSION=${PGVERSION:-10}

apt install -y postgresql-$PGVERSION postgresql-server-dev-$PGVERSION
echo 'local all all trust' > /etc/postgresql/$PGVERSION/main/pg_hba.conf
echo "port = $PGPORT" >> /etc/postgresql/$PGVERSION/main/postgresql.conf
pg_ctlcluster $PGVERSION main start
export PG_CONFIG=/usr/lib/postgresql/$PGVERSION/bin/pg_config
make clean && make && make install
psql -Atc 'alter system set shared_preload_libraries to pg_store_plans, pg_stat_statements'
pg_ctlcluster $PGVERSION main restart
make installcheck

# some pgbench
psql -c 'CREATE EXTENSION pg_store_plans'
pgbench -i -s 10
pgbench -j 2 -c 10 -T 60 -P 1
psql -x -c 'select * from pg_store_plans'
