#!/bin/bash

ROLEPATH="/var/lib/postgresql/.ROLE" 
TGZPATH=$1

function stderr() {
    echo 1>&2 "${*}"
}

if [ ! "$TGZPATH}" ] ; then
    stderr "$0: Cannot see ${TGZPATH}"
    exit 1
fi

if [ -f "${ROLEPATH}" ] ; then
    . "${ROLEPATH}"
else
    ROLE=backup
fi

DATE=$(date +%Y%m%d-%H%M%S)
FILEPATH="${ROLE}-${DATE}-basebackup.tgz"
set -x
pg_basebackup --pgdata=- --format=tar --wal-method=fetch -U postgres | bzip2 -9 > "${FILEPATH}"

