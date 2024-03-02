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
    FILEPATH="db/${ROLE}/lib/${HOSTNAME}-${DATE}-basebackup.tgz"
    set -x
    #pg_basebackup --pgdata=- --format=tar --wal-method=fetch -U postgres | bzip2 -9 > "${FILEPATH}"
    stderr 
    stderr "dumpall: creating compressed sql backup: ${FILEPATH}"
    (set -x; docker exec --user postgres -i postgresql_racedb_${ROLE} \
        pg_basebackup --pgdata=- --format=tar --wal-method=fetch -U postgres 
    ) | gzip -9 > "${FILEPATH}"

}

restore_tgz() {
    stderr
    stderr "Will restore $1 before starting"
    pushd db/primary/lib
    ln -svf $(basename $1) recover-db.tgz
    popd
}

restore_standby() {
    stderr
    stderr "Will restore $1 before starting"
    set -x 
    touch db/primary/lib/restore-standby
    set +x
}

loaddata() {
    pathname=$1

    if [ "-" = "${pathname}" ]; then
        echo "Importing from <stdin>"
        set -x
        docker exec racedb_8080_primary "echo yes | python3 /RaceDB/manage.py flush --no-input"
        cat > db/primary/racedb-loaddata/stdin.json
        docker exec racedb_8080_primary python3 /RaceDB/manage.py loaddata --format=json /racedb-loaddata/stdin.json
        rm -vf db/primary/racedb-loaddata/stdin.json

    elif [ -n "${pathname}" ] ; then

        #if [ !  -f "racedb-data/${pathname}" ];then
        #    echo "racedb-data/${pathname} does not exist"
        #    exit 1
        #fi
        echo "Importing racedb-data/${pathname}..."

        set -x
        docker exec racedb_8080_primary "echo yes | python3 /RaceDB/manage.py flush --no-input"
        filename=$(basename ${pathname})
        cp -v ${pathname} db/primary/racedb-loaddata/${filename}
        (set -x; docker exec racedb_8080_primary python3 /RaceDB/manage.py loaddata --format=json /racedb-loaddata/${filename} )
        #rm -vf db/primary/racedb-loaddata/${filename}
    fi

}

dumpdata() {
    filename=$1

    if [ "-" = "${filename}" ]; then
        echo "Exporting to <stdout>"
        set -x
        docker exec racedb_8080_primary python3 /RaceDB/manage.py dumpdata core --indent 2

    else
        if [ -z "$filename" ]; then
            filename="${HOSTNAME}-racedb-export-${DATE}.json"
        fi
        echo "Exporting from racedb_8080_primary to ${filename}..."
        set -x
        ( set -x; docker exec racedb_8080_primary python3 /RaceDB/manage.py dumpdata core --indent 2 ) > ${filename}
        set +x
        echo "Export saved to ${filename}..."
    fi

}
bash() {
    set -x
    docker exec -ti $1 /bin/bash
}
qlstatus() {
    IPADDRESS=$(docker exec qlmuxd sed -n -e 's/qlmuxd.local//' -e 's/ *qlmuxd//p' /etc/hosts)
    telnet $IPADDRESS 9100
}
racedb_ssh() {
    docker exec -ti racedb_8080_primary ssh racedb@qllabels.local pwd
}

# ###############################################################################################################################
# Verify that STANDBY containers are not running!

if [ ${POSTGRESQL_RACEDB_STANDBY_RUNNING} -eq 1 ] ; then
    stderr
    stderr "STANDBY Containers are running, cannot run PRIMARY at the same time"
    stderr "Use ./standby.sh stop first if you wish to use the PRIMARY container set"
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
    stderr "    systeminfo          - load systeminfo.json"
    stderr
    stderr "    restore_basebackup  - restore from local basebackup and start"
    stderr "    restore_standby     - restore from local standby in failover mode and start"
    stderr "    restore_tgz         - restore from local filesystem backup and start"
    stderr "    host                - restore from another host and start"
    stderr "    pull                - pull new images if any are available"
    stderr "    backup_db           - \$PGDATA file system backup to $filename"
    stderr 
    exit 0

}

if [ ! ${POSTGRESQL_RACEDB_PRIMARY_RUNNING} -eq 1 ] ; then
    case "${CMD}" in
        restore_tgz | tgz ) restore_tgz ${*} ;;
        restore_standby | standby | failover | fail) restore_standby ;;
        start ) start;;
        erase_db) erase_db;;
        backup_db | tgz) db_tgz;;
        help | *) usage_notrunning;;
    esac
    exit 0
fi

# ###############################################################################################################################
# Running
usage_running() {
    filename="${HOSTNAME}-racedb-export-${DATE}.json"

    stderr 
    stderr "${ARG0} Commands:"
    stderr "    help                - display usage"
    stderr "    restart             - stop and restart RaceDB as ${ROLE^^}"
    stderr "    stop                - stop RaceDB as ${ROLE^^}"
    stderr "    basebackup          - do a pg_basebackup"
    stderr "    loaddata file       - import json data from file into RaceDB with manage.py loaddata"
    stderr "    loaddata -          - import json data from <stdin> into RaceDB with manage.py loaddata"
    stderr "    dumpdata file       - dump json data from RaceDB with manage.py dumpdata into file"
    stderr "    dumpdata -          - dump json data from RaceDB with manage.py dumpdata to <stdout>"
    stderr "    dumpdata            - dump json data from RaceDB with manage.py dumpdata to $filename"
    #stderr "    restore_sql     - restore from local sql backup and start"
}

if [ ${POSTGRESQL_RACEDB_PRIMARY_RUNNING} -eq 1 ] ; then
    case "${ROLE}-${CMD}" in
        restore-sql) restore_sql ${*} ;;
    esac
    case "${CMD}" in
        restart ) restart ;;
        stop ) stop ;;
        basebackup | base) basebackup;;
        systeminfo ) loaddata systeminfo.json;;
        loaddata) loaddata ${*};;
        dumpdata) dumpdata;;
        pull) pull;;
        racedb) bash racedb_8080_primary;;
        racedb_ssh) racedb_ssh;;
        qllabels) bash qllabels_qlmuxd;;
        qlmuxd) bash qlmuxd;;
        qlstatus) qlstatus;;
        help | *)  usage_running;;
    esac
    exit 0
fi

exit 0

