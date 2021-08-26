#!/bin/bash

echo
echo $*
echo
echo Postgresql entrypoint
env


function stderr() {
    echo 1>&2 "${*}"
}

testandadd() {
    set -x
    file=$1 
    add=$2
    egrep -q "^${add}" "${file}" || echo "${add}" >> "${file}"

}
stderr $(date)
#stderr "Test and Add: "
#testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = 'replication.conf'"

ROLE=${POSTGRESQL_ROLE,,}
stderr "Role: ${POSTGRESQL_ROLE}"
stderr "Role: ${ROLE}"

set -x
case ${ROLE} in
    master )
        stderr "POSTGRESQL_ROLE master."

        # First time 
        #
        # Already setup, continue
        #
        # Promoted from standby
        #
        ;;
    standby )

        stderr "POSTGRESQL_ROLE standby."

        # Demoted from master or First time
        #   - verify access to master
        until ping -c 1 -W 1 MASTERHOST; do
            stderr "Waiting for ping from ${MASTGERHOST}"
            sleep 1
        done

        #   - remove current database files
        rm -rfv /var/lib/postgresql/data/*

        #   - copy from master
        #   - set flags to indicate setup
        #
        ;;
    * )
        stderr "POSTGRESQL_ROLE environment variable not set."
        ;;
esac 

stderr "Continue:"

exec /usr/local/bin/docker-entrypoint.sh postgres


