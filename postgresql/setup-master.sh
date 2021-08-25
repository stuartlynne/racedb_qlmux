#!/bin/bash

stderr() {
    echo 1>&2 "${*}"
}

stderr "----------"
stderr "setup-master"
env
stderr "----------"
case "${POSTGRESQLROLL,,}" in
    master)
        stderr "POSTGRESQLROLL master."
        ;;
    standby)
        stderr "POSTGRESQLROLL standby - skipping."
        exit 0
        ;;
    *)
        stderr "POSTGRESQLROLL environment variable unknown not set - skipping."
        exit 0
        ;;
esac 

set -ex
#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
psql -v ON_ERROR_STOP=1 --username postgres  <<-EOSQL
CREATE USER $POSTGRES_USER REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '$PG_REP_PASSWORD'; \du;
EOSQL


#stderr "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

#cat >> ${PGDATA}/postgresql.conf <<EOF
#wal_level = hot_standby
#archive_mode = on
#archive_command = 'cd .'
#max_wal_senders = 8
#wal_keep_segments = 8
#hot_standby = on
#EOF
