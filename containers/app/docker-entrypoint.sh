#!/usr/bin/env bash

function interrupt () {
  printf "\nCaras-Framework boot process is interrupted.\n"
  exit 1
}

trap interrupt INT

function wait_for_postgres () {
  printf "Waiting for postgres to be up" >&2
  until psql -h "$DB_HOST" -U "postgres" -c "\l" > /dev/null 2>&1; do
    printf "." >&2
    sleep 1
  done
  printf "\n"  >&2
}

function print_usage () {
  printf "Usage :\n" >&2
  printf "$ cd /path/to/caras-framework/\n" >&2
  printf "$ docker-compose run --rm app\n" >&2
  printf "See https://github.com/gsx-lab/caras-framework/blob/master/docs/INSTALL.md#install-on-docker\n" >&2
}

# DB_HOST declared?
if [ -z "$DB_HOST" ]; then
  printf "Environment variable 'DB_HOST' must be declared\n" >&2
  print_usage
  exit 1
fi

# create config files if not exist.
if [ ! -f ${APPDIR}/config/database.yml ]; then
  cp ${APPDIR}/config/database.yml.sample ${APPDIR}/config/database.yml
fi
if [ ! -f ${APPDIR}/config/environment.yml ]; then
  cp ${APPDIR}/config/environment.yml.sample ${APPDIR}/config/environment.yml
fi

bundle check --path vendor/bundle > /dev/null 2>&1 || bundle install --path vendor/bundle
yarn check > /dev/null 2>&1 || yarn install

wait_for_postgres

bundle exec rake db:setup

exec "$@"
