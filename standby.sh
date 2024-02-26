#!/bin/bash
#set -x

export ROLE="standby"

. ./scripts/common.sh

# ###############################################################################################################################

failover() {
    stderr "Configuring Failover" 
    set -x
    touch "${TRIGGERPATH}"
    set +x
}

reset_failover() {
    if [ -f "${TRIGGERPATH}" ] ; then
        stderr "Reseting Failover - removing ${TRIGGERPATH}" 
        rm -fv "${TRIGGERPATH}"
    else
        stderr "Reseting Failover - cannot see ${TRIGGERPATH}" 
    fi
}

# ###############################################################################################################################
# Verify that PRIMARY containers are not running!

if [ ${POSTGRESQL_RACEDB_PRIMARY_RUNNING} -eq 1 ] ; then
    stderr
    stderr "PRIMARY Containers are running, cannot run STANDBY at the same time"
    stderr "Use ./primary.sh stop first if you wish to use the STANDBY container set"
    stderr
    exit 1
fi

# ###############################################################################################################################
# Not Running
usage_notrunning() {
    filename="${HOSTNAME}-${DATE}-db.tgz"
    stderr 
    stderr "${ARG0} Commands:"
    stderr
    stderr "    help                - display usage"
    stderr "    start               - start ${role} RaceDB container set"
    stderr "    pull                - pull new images if any are available"
    stderr "    backup_db           - \$PGDATA file system backup to $filename"
    if [ -f "${TRIGGERPATH}" ] ; then
    stderr "    reset_failover      - remove ${TRIGGERPATH}"
    fi
    stderr 
    exit 0

}

if [ ! ${POSTGRESQL_RACEDB_STANDBY_RUNNING} -eq 1 ] ; then
    case "${CMD}" in
        start ) start;;
        pull) pull;;
        backup_db | tgz) db_tgz;;
        reset_failover | reset) reset_failover;;
        help | *) usage_notrunning;;
    esac
    exit 0
fi

# ###############################################################################################################################
# Running
usage_running() {
    stderr 
    stderr "${ARG0} Commands:"
    stderr "    help                - display usage"
    stderr "    restart             - stop and restart RaceDB as ${ROLE^^}"
    stderr "    stop                - stop RaceDB as ${ROLE^^}"
    stderr "    failover            - promote STANDBY server to FAILOVER PRIMARY"
}

if [ ${POSTGRESQL_RACEDB_STANDBY_RUNNING} -eq 1 ] ; then
    case "${ROLE}-${CMD}" in
        restore-sql) restore_sql ${*} ;;
    esac
    case "${CMD}" in
        restart ) restart ;;
        stop ) stop ;;
        failover | fail | fall | fallover ) failover;;
        logs) logs $1;;
        help | *)  usage_running;;
    esac
    exit 0
fi

exit 0


        
