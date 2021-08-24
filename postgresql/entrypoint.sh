#!/bin/bash

echo $*
echo Postgresql entrypoint

testandadd() {
    set -x
    file=$1 
    add=$2
    egrep -q "^${add}" "${file}" || echo "${add}" >> "${file}"

}
set -x
testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = 'replication.conf'"


exec /usr/local/bin/docker-entrypoint.sh postgres


