#!/bin/bash

function stderr() {
    echo 1>&2 "${*}"
}

# N.B. DATABASE_TYPE is inherited from esitarksi/racedb and normally will default to psql-local
# We do not support any other configuration.

stderr 
stderr "-----------------------------------------------"
stderr "02-postgress.sh"
stderr "DATABASE_TYPE: $DATABASE_TYPE"
stderr "-----------------------------------------------"
date
env


waitfordb() {
    stderr "Waiting for Postgres to start up..."
    until ./check.sh; do
        stderr "$(date): Postgres is unavailable - sleeping"
        sleep 10
    done
    stderr "$(date): Postgres appears up."
    set +x
}
createuser() {
stderr "Creating $DATABASE_NAME database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_USER" <<-EOSQL
CREATE USER $DATABASE_USER;
CREATE DATABASE $DATABASE_NAME;
GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;
EOSQL
}
checkuser() {
    stderr "Checking if the $DATABASE_NAME exists..."
    racedb=$(psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME'")
    if [ "$racedb" != "1" ]; then
        stderr "RaceDB DB DOES NOT exist. Creating."
        createuser
        # POSTGRES_USER is the same as the postgres database name
    else
        stderr "RaceDB DB DOES exist. Not creating."
    fi
}

if [ ! "$DATABASE_TYPE" == "psql-local" ]; then
    stderr "Ignoring Postgres startup on non-postgres database"
    exit 0
fi

stderr "--------------------"

stderr "Start simply http server"
(cd /var/local/www; python3 /simple.py) &

stderr "Start witing for db"
waitfordb

stderr "Killing simple http server"
CHILDREN=$(pgrep -f simple.py)
stderr CHILDREN: $CHILDREN
for p in ${CHILDREN} ; do
    kill -1 $p
    done
stderr PS
ps auwx
stderr JOBS
jobs -p
stderr
checkuser

stderr "***************************************************************"
set -x

