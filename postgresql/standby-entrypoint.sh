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

# Ensure that that a valid ROLE is set, does /var/lib/postgresql/.ROLE exist and is it valid
#
ROLEPATH="/var/lib/postgresql/.ROLE" 
ARGSPATH="/var/lib/postgresql/.ARGS" 
unset ROLE
#set -x
while [ -z "${ROLE}" ] ; do

    if [ ! -f "${ROLEPATH}" ] ; then
        stderr "Cannot find ${ROLEPATH}, use manage.sh standby | primary to set"
        sleep 10
        continue
    fi

    . "${ROLEPATH}"
    case "${ROLE}" in
    primary | hot_standby | restore ) 
        stderr "Found ROLE: $ROLE"
        break
        ;;
    *) 
        stderr "ROLE: \"${ROLE}\" is not primary or standby or restore_xxx"
        unset ROLE
        sleep 10
        ;;
    esac
done

stderr ROLE: ${ROLE}
stderr PGDATA: ${PGDATA}
stderr PRIMARY_HOST: ${PRIMARY_HOST}
stderr TRIGGER_FILE: ${TRIGGER_FILE}
stderr ARGSPATH: ${ARGSPATH}

# backup PGDATA directory to $(basename $PGDATA)/...
#
if [ -d "${PGDATA}" ] ; then
    KB=$(du -sk "${PGDATA}" | cut -f1)
    stderr KB: $KB
    DATE=$(date +%Y%m%d-%H%M)
    BACKUP="$(dirname ${PGDATA})/${ROLE}-${DATE}.tgz"
    #DIR="$(dirname ${PGDATA})"
    stderr "Archiving ${PGDATA} to ${BACKUP}"
    set -x
    tar cfz "${BACKUP}" -C "${PGDATA}" .
    set +x
fi

#restore_local() {
#    stderr "restore_local: $1"
#    TGZPATH="/var/lib/postgresql/${1}"
#    if [ ! -f "${TGZPATH}" ] ; then
#        stderr "restore_local: CANNOT FIND $TGZPATH"
#        return
#    fi
#    stderr "restore_local: REMOVING OLD"
#    pushd /var/lib/postgresql/data
#    pwd
#    #rm -rfv *
#    #ls -ltra
#    #stderr "restore_local: RESTORING FROM $1"
#    #pushd -v /var/lib/postgresql/
#    tar xvfz "${TGZPATH}"
#    ls -ltra
#    sleep 30
#    #set +x
#}
#restore_host() {
#    stderr "restore_host: $1"
#}

#primary_with_args() {
#    CMD=$1
#    case "${CMD}" in
#    restore_sql) return ;;
#    restore_local) restore_local $2 ;;
#    restore_host) restore_host $2;;
#    esac
#    rm -vf "${ARGSPATH}"
#}


case "${ROLE}" in

primary | restore* )
    stderr 
    stderr "**********************************************"
    stderr "Starting Postgress as PRIMARY Server"
    stderr "**********************************************"

    set -x
    [ -f "${STANDBY_CONF}" ] && rm -fv "${STANDBY_CONF}"
    [ -f "${TRIGGER_FILE}" ] && rm -rf "${TRIGGER_FILE}"
    set +x
    stderr "**********************************************"
    set -x
    exec /usr/local/bin/docker-entrypoint.sh postgres
    ;;

hot_standby)
        stderr 
        stderr "**********************************************"
        stderr "Starting Postgress as HOT-STANDBY server."
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
        stderr "Backing up from ${PRIMARY_HOST} ..."
        until time pg_basebackup -R -h ${PRIMARY_HOST} -D "${PGDATA}" -U postgres -vP ; do
            stderr "Waiting for ${PRIMARY_HOST} to accept connection ..."
            sleep 1
        done
        
        # hot_standby configuration must be done after pg_basebackup completes
        #
        stderr "Setup up standby.conf, add to postgress.conf and create standby.signal"
        createstandbyconf > "${STANDBY_CONF}"
        testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${STANDBY_CONF}'"
        touch "${PGDATA}/standby.signal"
        [ -f "${TRIGGER_FILE}" ] && rm -vf "${TRIGGER_FILE}"
        set -x
        exec /usr/local/bin/docker-entrypoint.sh postgres
    ;;

failover)
        stderr 
        stderr "*******************************************************"
        stderr "Starting Postgress as HOT-STANDBY server FAILOVER mode."
        stderr "Using existing data."
        stderr "*******************************************************"
        stderr
        stderr "Setup up standby.conf, add to postgress.conf, create standby.signal and trigger_file"
        createstandbyconf > "${STANDBY_CONF}"
        testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${STANDBY_CONF}'"
        set -x
        touch "${PGDATA}/standby.signal" "${TRIGGER_FILE}"
        set -x
        exec /usr/local/bin/docker-entrypoint.sh postgres
    ;;


*)
    while true; do
        stderr "$(date): Unknown Role: ${ROLE}"
        sleep 60
    done
    ;;
esac

