#!/bin/bash
#set -x

export ROLE="primary"

. ./scripts/common.sh

erase_db() {
    stderr "Erasing DB ..."
    set -x
    rm -rfv ${VARDATA}/*
    set +x
}

basebackup() {
    DATE=$(date +%Y%m%d-%H%M%S)
    FILEPATH="db/${ROLE}/lib/${DATE}-basebackup.tgz"
    set -x
    #pg_basebackup --pgdata=- --format=tar --wal-method=fetch -U postgres | bzip2 -9 > "${FILEPATH}"
    stderr 
    stderr "dumpall: creating compressed sql backup: ${FILEPATH}"
    (set -x; docker exec --user postgres -i postgresql_racedb_${ROLE} \
        pg_basebackup --pgdata=- --format=tar --wal-method=fetch -U postgres 
    ) | gzip -9 > "${FILEPATH}"

}


# ###############################################################################################################################


# ###############################################################################################################################
# Not Running
usage_notrunning() {
    stderr 
    stderr "${ARG0} Commands:"
    stderr
    stderr "    help            - display usage"
    stderr "    start           - start ${role} RaceDB container set"
    stderr
    stderr "    restore_basebackup - restore from local basebackup and start"
    stderr "    restore_tgz - restore from local filesystem backup and start"
    stderr "    host - restore from another host and start"
    stderr 
    exit 0

}

if [ ! ${POSTGRESQL_RACEDB_PRIMARY_RUNNING} -eq 1 ] ; then
    case "${CMD}" in
        restore_tgz) restore_tgz ${*} ;;
        start ) start;;
        erase_db) erase_db;;
        help | *) usage_notrunning;;
    esac
    exit 0
fi

# ###############################################################################################################################
# Running
usage_running() {
    stderr 
    stderr "${ARG0} Commands:"
    stderr "    help            - display usage"
    stderr "    restart         - stop and restart RaceDB as ${ROLE^^}"
    stderr "    stop            - stop RaceDB as ${ROLE^^}"
    stderr "    basebackup      - do a pg_basebackup"
    stderr "    restore_sql     - restore from local sql backup and start"
}

if [ ${POSTGRESQL_RACEDB_PRIMARY_RUNNING} -eq 1 ] ; then
    case "${ROLE}-${CMD}" in
        restore-sql) restore_sql ${*} ;;
    esac
    case "${CMD}" in
        restart ) restart ;;
        stop ) stop ;;
        basebackup | base) basebackup;;
        help | *)  usage_running;;
    esac
    exit 0
fi

exit 0


        
