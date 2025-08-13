#!/bin/bash -ex

sudo apt-get update
sudo apt-get install -y git curl ca-certificates gnupg lsb-release build-essential
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg > /dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update
sudo apt-get install -y postgresql-$PG_VERSION postgresql-server-dev-$PG_VERSION
export PG_CONFIG=/usr/lib/postgresql/$PG_VERSION/bin/pg_config
make installcheck
