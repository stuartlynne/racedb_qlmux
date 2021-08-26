#!/bin/bash

# This is run from /docker-entrypoint-initdb.d/  by postgres when it has just initialized a new database.
#
# We need to update configuration files in /var/lib/postgresql/data that are only available
# to be changed after the initialization, so cannot be changed in entrypoint.sh.
#


stderr() {
    echo 1>&2 "${*}"
}

stderr "----------"
stderr "setup-master"
env
stderr "----------"
case "${POSTGRESQL_ROLE,,}" in
    master)
        stderr "POSTGRESQL_ROLE master."
        set -ex
        #psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        #psql -v ON_ERROR_STOP=1 --username postgres  <<-EOSQL
        #CREATE USER $POSTGRES_USER REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '$PG_REP_PASSWORD'; \du;
        #EOSQL
        echo "host replication "postgres" 0.0.0.0/0 trust" >> "/var/lib/postgresql/data/pg_hba.conf"
        #echo "host replication "postgres" 192.168.40.17/24 trust" >> "/var/lib/postgresql/data/pg_hba.conf"

        ;;
    standby)
        stderr "POSTGRESQL_ROLE standby - skipping."
        exit 0
        ;;
    *)
        stderr "POSTGRESQL_ROLE environment variable unknown not set - skipping."
        exit 0
        ;;
esac 




#cat >> ${PGDATA}/postgresql.conf <<EOF
#wal_level = hot_standby
#archive_mode = on
#archive_command = 'cd .'
#max_wal_senders = 8
#wal_keep_segments = 8
#hot_standby = on
#EOF
