#!/bin/bash
#
# This is the entrypoint file used for the Docker Postgresql Standby Container.
#
# A standby server can be in two modes:
#
#   hot_standby replicating data from the primary server
#   failover    The postgress server is acting as a failover postgress server for RaceDB
#

function stderr() {
    echo 1>&2 "${*}"
}

stderr 
stderr "**********************************************"
stderr "Starting Postgress as STANDBY Server"
stderr "**********************************************"
stderr "PRIMARY_HOST: $PRIMARY_HOST"
stderr "DEFAULT_PRIMARY_HOST: $DEFAULT_PRIMARY_HOST"
stderr $0: $(date)
stderr

if [ -z "${PRIMARY_HOST}" ]; then
    stderr "PRIMARY_HOST is not set, using DEFAULT_PRIMARY_HOST: $DEFAULT_PRIMARY_HOST"
    export PRIMARY_HOST="${DEFAULT_PRIMARY_HOST}"
fi

#env 1>&2

# testand file "config=value"
# If ^$2 is not found in $1, then append $2 >> $1
#
testandadd() {
    #set -x
    file=$1 
    add=$2
    egrep -q "^${add}" "${file}" || echo "${add}" >> "${file}"
}

STANDBYSIGNAL="${PGDATA}/standby.signal"
RECOVERYSIGNAL="${PGDATA}/recovery.signal"
RECOVER_CONF="${PGDATA}/recover.conf"
RECOVERDBTGZ="recover-db.tgz"
HOSTNAME=$(hostname -s)


export TRIGGER_FILE="$(dirname ${PGDATA})/trigger_file_standby_to_failover"
export STANDBY_CONF="${PGDATA}/standby.conf"

# testand file "config=value"
# If ^$2 is not found in $1, then append $2 >> $1
#
testandadd() {
    #set -x
    file=$1 
    add=$2
    egrep -q "^${add}" "${file}" || echo "${add}" >> "${file}"
}
# createstandbyconf 
# Used to create /var/lib/postgresql/data/standby.conf
#
createstandbyconf() {
cat <<EOF
primary_conninfo = 'host=${PRIMARY_HOST} port=5432 user=postgres'
promote_trigger_file = '${TRIGGER_FILE}'
primary_slot_name = 'standby1_slot'
hot_standby = on
wal_level = replica
EOF
}

ROLE=standby

stderr ROLE: ${ROLE}
stderr PGDATA: ${PGDATA}
stderr PRIMARY_HOST: ${PRIMARY_HOST}
stderr TRIGGER_FILE: ${TRIGGER_FILE}
stderr ARGSPATH: ${ARGSPATH}

# backup PGDATA directory to $(basename $PGDATA)/...
#
if [ -d "${PGDATA}" ] ; then
    stderr "Backing up previous STANDBY database ..."
    KB=$(du -sk "${PGDATA}" | cut -f1)
    stderr KB: $KB
    DATE=$(date +%Y%m%d-%H%M)
    BACKUP="$(dirname ${PGDATA})/${HOSTNAME}-${DATE}-db.tgz"
    stderr "Archiving ${PGDATA} to ${BACKUP}"
    set -x
    tar cfz "${BACKUP}" -C "${PGDATA}" .
    set +x
fi

#createstandbyconf > "${STANDBY_CONF}"
#testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${STANDBY_CONF}'"

if [ ! -f "${TRIGGER_FILE}" ] ; then
    stderr 
    stderr "**********************************************"
    stderr "Starting Postgress as a STANDBY server."
    stderr "Existing data will be archived."
    stderr "**********************************************"
    # use ping to verify we can see the primary host
    #
    stderr "Verifying ${PRIMARY_HOST} is alive ..."
    until ping -c 1 -W 1 ${PRIMARY_HOST}; do
        stderr "Waiting for ping from ${PRIMARY_HOST}"
        sleep 1
    done

    # remove old data, ensure we have a PGDATA directory
    #
    if [ -d "${PGDATA}" ] ; then
        rm -rf "${PGDATA}"/*
    else
        mkdir -vp "${PGDATA}"
    fi

    # use pg_basebackup to pull the database over from the primary host
    #
    stderr "Replicating from ${PRIMARY_HOST} ..."
    set -x
    until time pg_basebackup -R -h ${PRIMARY_HOST} -D "${PGDATA}" -U postgres -vP ; do
        set +x
        stderr "Waiting for ${PRIMARY_HOST} to accept connection ..."
        sleep 1
        set -x
    done
    set +x
    
    # hot_standby configuration must be done after pg_basebackup completes
    #
    #stderr "Setup up standby.conf, add to postgress.conf and create standby.signal"
    #touch "${PGDATA}/standby.signal"
    #[ -f "${TRIGGER_FILE}" ] && rm -vf "${TRIGGER_FILE}"
    createstandbyconf > "${STANDBY_CONF}"
    testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${STANDBY_CONF}'"
    echo "host replication "postgres" 0.0.0.0/0 trust" >> "/var/lib/postgresql/data/pg_hba.conf"
    echo "SELECT pg_create_physical_replication_slot('standby1_slot');" | psql -U postgres
    touch "${LOCALCONFCOMPLETE}" 

else
    stderr 
    stderr "*******************************************************"
    stderr "Starting Postgress as a STANDBY server in FAILOVER mode."
    stderr "Using existing data."
    stderr "*******************************************************"
    stderr

fi

set -x
exec /usr/local/bin/docker-entrypoint.sh postgres
