#!/bin/bash
#
# This is the entrypoint file used for the Docker Postgresql Primary Container.
# 

function stderr() {
    echo 1>&2 "${*}"
}

stderr 
stderr "**********************************************"
stderr "Starting Postgress as PRIMARY Server"
stderr "**********************************************"
stderr $0: $(date)
stderr
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
RESTORESTANDBY="restore-standby"
LOCALCONFCOMPLETE="${PGDATA}/localconfcomplete"
HOSTNAME=$(hostname -s)

TRIGGER_FILE="$(dirname ${PGDATA})/trigger_file_standby_to_failover"
STANDBY_CONF="${PGDATA}/standby.conf"

if [ -z "${STANDBY_HOST}" ]; then
    stderr "STANDBY_HOST is not set, using DEFAULT_STANDBY_HOST: $DEFAULT_STANDBY_HOST"
    export STANDBY_HOST="${DEFAULT_STANDBY_HOST}"
fi

# if recover-db.tgz exists, unpack it into $PGDATA
#
if [ -f "${PGLIB}/${RECOVERDBTGZ}" ] ; then

    stderr "Recovering database ..."
    ls -l "${PGLIB}/${RECOVERDBTGZ}"
    DATE=$(date +%Y%m%d-%H%M)
    pushd ${PGDATA}
    set -x
    rm -rf *
    tar xfz "${PGLIB}/${RECOVERDBTGZ}"
    set +x 
    popd
    mv -v "${PGLIB}/${RECOVERDBTGZ}" "${PGLIB}/recovered-${DATE}-${RECOVERDBTGZ}"

# if restore-standby exists, attempt to restore from the standby server in failover mode
#
elif [ -f "${PGLIB}/${RESTORESTANDBY}" ] ; then
    stderr "Recovering database from STANDBY: ${STANDBY_HOST}"
    DATE=$(date +%Y%m%d-%H%M)

    stderr "Verifying ${STANDBY_HOST} is alive ..."
    until ping -c 1 -W 1 ${STANDBY_HOST}; do
        stderr "Waiting for ping from ${STANDBY_HOST}"
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
    stderr "Replicating from ${STANDBY_HOST} ..."
    set -x
    until time pg_basebackup -R -h ${STANDBY_HOST} -D "${PGDATA}" -U postgres -vP ; do
        set +x
        stderr "Waiting for ${STANDBY_HOST} to accept connection ..."
        sleep 1
        set -x
    done
    set +x

    mv -v "${PGLIB}/${RESTORESTANDBY}" "${PGLIB}/restored-${DATE}-from-${STANDBY_HOST}"

    if [ -f "${STANDBYSIGNAL}" ] ; then
        stderr "Removing ${STANDBYSIGNAL}"
        rm -v "${STANDBYSIGNAL}"
    fi
    if [ -f "${STANDBY_CONF}" ] ; then
        stderr "Removing ${STANDBY_CONF}"
        rm -v "${STANDBY_CONF}"
    fi


# backup PGDATA directory to $(basename $PGDATA)/...
#
elif [ -d "${PGDATA}" ] ; then
    stderr "Backing up database ..."
    KB=$(du -sk "${PGDATA}" | cut -f1)
    stderr KB: $KB
    DATE=$(date +%Y%m%d-%H%M)
    BACKUP="$(dirname ${PGDATA})/${HOSTNAME}-${DATE}-db.tgz"
    stderr "Archiving ${PGDATA} to ${BACKUP}"
    set -x
    tar cfz "${BACKUP}" -C "${PGDATA}" .
    set +x
fi
stderr "**********************************************"

#if [ -f "${RECOVERYSIGNAL}" ] ; then
#    testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${RECOVER_CONF}'"
#fi

if [ ! "${LOCALCONFCOMPLETE}" ] ; then
    set -x
    echo "host replication "postgres" 0.0.0.0/0 trust" >> "/var/lib/postgresql/data/pg_hba.conf"
    echo "SELECT pg_create_physical_replication_slot('standby1_slot');" | psql -U postgres
    touch "${LOCALCONFCOMPLETE}" 
    set +x
fi


exec /usr/local/bin/docker-entrypoint.sh postgres


