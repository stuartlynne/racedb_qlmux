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

# ###############################################################################################################################
# Not Running
usage_notrunning() {
    stderr 
    stderr "${ARG0} Commands:"
    stderr
    stderr "    help            - display usage"
    stderr "    start           - start ${role} RaceDB container set"
    stderr 
    exit 0

}

if [ ! ${POSTGRESQL_RACEDB_STANDBY_RUNNING} -eq 1 ] ; then
    case "${ROLE}-${CMD}" in
        start ) start;;
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
    stderr "    failover        - promote STANDBY server to FAILOVER PRIMARY"
}

if [ ${POSTGRESQL_RACEDB_STANDBY_RUNNING} -eq 1 ] ; then
    case "${ROLE}-${CMD}" in
        restore-sql) restore_sql ${*} ;;
    esac
    case "${CMD}" in
        restart ) restart ;;
        stop ) stop ;;
        failover | fail) failover;;
        help | *)  usage_running;;
    esac
    exit 0
fi

exit 0


        
