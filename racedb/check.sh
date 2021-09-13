#!/bin/bash
function stderr() {
    echo 1>&2 "${*}"
}

#F=$(echo 'SELECT TRIM(LEADING FROM pg_is_in_recovery());' | psql -U postgres --tuples-only )


STANDBYSIGNAL="${PGDATA}/standby.signal"
RECOVERYSIGNAL="${PGDATA}/recovery.signal"
RECOVER_CONF="${PGDATA}/recover.conf"

if [ -f "${STANDBYSIGNAL}" ] ; then
    stderr "Postgressql - STANDBY operation"
    exit 1
fi

if [ -f "${RECOVERYSIGNAL}" ] ; then
    stderr "Postgressql - RECOVERY operation"
    exit 1
fi


F=$(echo 'SELECT pg_is_in_recovery();' | psql -U postgres --tuples-only ) || exit 1

case $F in
	*f*) 
        stderr "Postgressql - PRIMARY operation"
        exit 0;
        ;;
	*t*) 
        stderr "Postgressql - STANDBY or RECOVERY operation"
        stderr standby; 
        exit 1;
            ;;
	*) 
        stderr "Postgressql - UNKNOWN"
        stderr F: \"$F\" 
        exit 1;
        ;;
esac
