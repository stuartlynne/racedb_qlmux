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

# if recover-db.tgz exists, unpack it into $PGDATA
#
if [ -f "${PGLIB}/${RECOVERDBTGZ}" ] ; then

    stderr "Recoving database ..."
    DATE=$(date +%Y%m%d-%H%M)
    pushd ${PGDATA}
    set -x
    rm -rf *
    tar xfz "${PGLIB}/${RECOVERDBTGZ}"
    set +x 
    popd
    mv -v "${PGLIB}/${RECOVERDBTGZ}" "${PGLIB}/recovered-${DATE}-${RECOVERDBTGZ}"

# backup PGDATA directory to $(basename $PGDATA)/...
#
elif [ -d "${PGDATA}" ] ; then
    stderr "Backing up database ..."
    KB=$(du -sk "${PGDATA}" | cut -f1)
    stderr KB: $KB
    DATE=$(date +%Y%m%d-%H%M)
    BACKUP="$(dirname ${PGDATA})/primary-${DATE}-db.tgz"
    stderr "Archiving ${PGDATA} to ${BACKUP}"
    set -x
    tar cfz "${BACKUP}" -C "${PGDATA}" .
    set +x
fi
stderr "**********************************************"

if [ -f "${RECOVERYSIGNAL}" ] ; then
    testandadd /var/lib/postgresql/data/postgresql.conf "include_if_exists = '${RECOVER_CONF}'"
fi


exec /usr/local/bin/docker-entrypoint.sh postgres


