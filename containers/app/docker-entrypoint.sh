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
