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
stderr "Test and Add: "
testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = 'replication.conf'"

ROLL=${POSTGRESQLROLL,,}
stderr "Roll: ${POSTGRESQLROLL}"
stderr "Roll: ${ROLL}"

set -x
case ${ROLL} in
    master )
        stderr "POSTGRESQLROLL master."

        # First time 
        #
        # Already setup, continue
        #
        # Promoted from standby
        #
        ;;
    standby )

        stderr "POSTGRESQLROLL standby."

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
        stderr "POSTGRESQLROLL environment variable not set."
        ;;
esac 

stderr "Continue:"

exec /usr/local/bin/docker-entrypoint.sh postgres


