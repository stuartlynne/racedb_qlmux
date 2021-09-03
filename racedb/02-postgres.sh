#!/bin/bash

function stderr() {
    echo 1>&2 "${*}"
}


stderr 
stderr "-----------------------------------------------"
stderr "02-postgress.sh"
stderr "-----------------------------------------------"
date
env

ROLEPATH="/var/lib/postgresql/.ROLE"

checkstandby() {

    if [ ! -f "${ROLEPATH}" ] ; then
        stderr "Cannot find ${ROLEPATH}"
        return 1
    fi

    . "${ROLEPATH}"

    case "${ROLE}" in
        hot_standby | restore) 
            stderr "Wating for ${ROLE^^} to change."
            return 1 ;;
        *) ;;
    esac
    
    F=$(stderr 'SELECT pg_is_in_recovery();' | psql -U postgres --tuples-only )
    case $F in
        *f*) return 1;;
        *t*) return 0;;
        *) stderr F: \"$F\"
            return 1;;
    esac
}


waitfordb() {
    stderr "Waiting for Postgres to start up..."
    until checkstandby; do
        stderr "Waiting for Postgress Role to change - sleeping"
        sleep 10
    done
    until ./check.sh; do
        stderr "Postgres is unavailable - sleeping"
        sleep 10
    done
    stderr Postgres appears up.
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
        createuser
        # POSTGRES_USER is the same as the postgres database name
    else
        stderr "RaceDB DB already exists. Not creating."
    fi
}

if [ "$DATABASE_TYPE" == "psql-local" ]; then
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


elif [ "$DATABASE_TYPE" == "psql" ]; then
    PG_PASSWORD="$DATABASE_PASSWORD"

    (cd /var/local/www; python3 /simple.py) &
    ID=$!!
    waitfordb
    set -x
    [[ -z "$(jobs -p)" ]] || kill -1 $(jobs -p)
    kill -1 %1
    set +x
    checkuser

else
    stderr "Ignoring Postgres startup on non-postgres database"
fi

stderr "***************************************************************"
set -x

