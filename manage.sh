#!/bin/bash
#set -x

ARG0=$(basename $0)


function stderr() {
    echo "${*}" 1>&2
}

YMLS=(  
    ./postgresql/docker-compose.yml 
    ./racedb/docker-compose.yml 
    ./racedb/docker-compose-network.yml 
#    ./qllabels-qlmuxd/docker-compose.yml
#    ./racedb/docker-compose-8080.yml 
#    ./racedb/docker-compose-8081.yml 
    )


POSTGRESS=( postgresql )
RACEDB=( racedb_8080 racedb_8081 )
QLMUXD=( qllabels_direct qllabels_qlmuxd )


VARLIB="./postgresql-varlib"
VARDATA="./postgresql-vardata"
INITDB="./postgresql-initdb.d"
ROLEPATH="${VARLIB}/.ROLE"
ARGSPATH="${VARLIB}/.ARGS"
OLDROLEPATH="${VARLIB}/.OLDROLE"
TRIGGERPATH="${VARLIB}/trigger_file_standby_to_failover"

_inspect() {
    RUNNING="$(docker inspect -f '{{.State.Running}}' $1)"
    stderr RUNNING: $RUNNING
    if [ -n "${RUNNING}" -a "${RUNNING}" = "true" ] ; then stderr inspect_OK; return 0 ; 
    else
    stderr inspect_NOT ;  return 1; fi
}

inspect() {
    _inspect $1 2>/dev/null > /dev/null
    #RC=$?
    #echo RC: $RC
    return $?
}
running() {
    #if [ "$(docker inspect -f '{{.State.Running}}' $1)" = "true" ]; then 
    #echo RC: $RC
    inspect $1 
    #RC=$?
    #if [ "$RC" -eq 0   ]; then 
    if [ $? -eq 0   ]; then 
        #stderr $1: OK ; 
        return 0; 
    else 
        #stderr $1: NOT; 
        return 1; 
    fi
}

checkpostgres() {
    BOOL=0
    for N in "${POSTGRESS[@]}"; do
        running $N
        if [ $? -eq 0 ] ;  then
            if [ $BOOL -eq 1 ] ; then
                stderr "Warning - second postgres container"
            fi
            stderr "Container $N running"
            BOOL=1
        fi
    done
    return $BOOL
}

checkracedb() {
    BOOL=0
    for N in "${RACEDB[@]}"; do
        running $N
        if [ $? -eq 1 ] ;  then
            stderr "Container $N running"
            BOOL=1
        fi
    done
    return $BOOL
}


#checkpostgres
#POSTGRESS_RUNNING=$?
#checkracedb
#RACEDB_RUNNING=$?

#echo POSTGRESS_RUNNING: $POSTGRESS_RUNNING
#echo RACEDB_RUNNING: $RACEDB_RUNNING

running postgresql_racedb && POSTGRESQL_RACEDB_RUNNING=1 || POSTGRESQL_RACEDB_RUNNING=0

#echo POSTGRESQL_RACEDB_RUNNING: $POSTGRESQL_RACEDB_RUNNING

#running racedb_8080
#running postgresql_primary
#running postgresql_standby

cmdlist() {

    for i in "${YMLS[@]}"; do 
        if [ ! -e "${i}" ] ; then
            stderr "Cannot find $i"
            exit 1
        fi
        echo -f "$i"; 
    done
}

YMLLIST=$(cmdlist)

roleusage() {
    stderr
    stderr "Postgress roll is not set."
    stderr
    stderr "Use ./manage.sh primary | standby to set database roll."
    stderr
    exit 1
}

setrole() {

case "${1}" in
failover) 
    set -x
    touch "${TRIGGERPATH}"
    set +x
    ;;
*) [ -f "${TRIGGERPATH}" ] && rm -fv "${TRIGGERPATH}" ;;
esac

[ -f "${ROLEPATH}" ] && cat "${ROLEPATH}" >> "${OLDROLEPATH}"

cat > "${ROLEPATH}" << EOF
# DO NOT HAND EDIT
# use ./manage.sh primary | hot_standby
ROLE=$1
EOF
}

osetargs() {
    stderr ARGSPATH: $ARGSPATH
    set -x
cat << EOF > "${ARGSPATH}"
${*}
EOF
    ls -ltra postgresql-varlib
}

#setargs() {
#    stderr ARGSPATH: $ARGSPATH
#    set -x
#    (echo "${*}") > "${ARGSPATH}"
#    #ls -ltra postgresql-varlib
#}


if [ -f "${ROLEPATH}" ] ; then
    . "${ROLEPATH}"
    case ${ROLE,,} in
        primary | hot_standby | failover | restore ) ;;
        *) ROLE=no_role ;;
    esac
    #stderr "ROLE: $ROLE"
fi

RACEDB=racedb_8080


DOCKERCMD="docker-compose ${YMLLIST}"

checkconfig() {
    stderr
    stderr ROLE: $ROLE
    stderr YMLLIST: $YMLLIST
    stderr DOCKERCMD: $DOCKERCMD

}


dumpall()
{
    DATE=$(date +%Y%m%d-%H%M%S)
    FILENAME="${VARLIB}/${ROLE}-${DATE}.sql.gz"
    stderr 
    stderr "dumpall: creating compressed sql backup: ${FILENAME}"
    ( docker exec --user postgres -i postgresql_racedb pg_dumpall --clean ) | gzip -9 > "${FILENAME}"
}


stop() {
    echo "Stopping RaceDB Container set..."
    set -x
    $DOCKERCMD stop
}

start() {
    echo "Starting RaceDB Container set..."
    set -x
    $DOCKERCMD up -d
}

restart() {
    stop
    sleep 2
    start
    $DOCKERCMD restart
}

failover() {
    if [ ${POSTGRESQL_RACEDB_RUNNING} -eq 1 ] ; then
        stderr "RaceDB Containers running, doing dumpall prior to failover"
        dumpall
    else
        stderr "RaceDB Containers not running, cannot dumpall first"
    fi
    stderr "Configuring Failover" 
    set -x
    setrole failover
}

fallback() {
    setrole hot_standby
    rm -fv "${VARLIBTRIGGERPATH}"
}

erase_db() {
    stderr "Erasing DB ..."
    set -x
    rm -rf "${VARDATA}"
    set +x
}

primary_restore_sql() {
#    setrole restore_sql    
#    setargs "SQLGZ=$(basename $1)"
    if [ ! -f "$1" ] ; then
        stderr "Cannot see $1"
        exit 1
    fi
    set -x
    gunzip < "$1" | docker exec -i --user postgres postgresql_racedb psql -v ON_ERROR_STOP=1 --username postgres --no-password 
    set +x
}

#primary_restore_local() {
#    setrole restore_local    
#    setargs "BACKUP=$(basename $1)"
#}

#primary_restore_host() {
#    setrole restore_local    
#    setargs "restore_host $1"
#}


pull() {
    echo "Starting RaceDB Container set..."
    set -x
    $DOCKERCMD pull
}

logs() {
    $DOCKERCMD logs
}

flogs() {
    $DOCKERCMD logs -f
}

bash() {
    echo "You are now running commands inside the racedb container"
    echo
    set -x
    $DOCKERCMD exec $RACEDB /bin/bash
}

manage() {
    $DOCKERCMD exec $RACEDB /RaceDB/manage.py $@
}

images() {
    $DOCKERCMD images 
}

services() {
    $DOCKERCMD ps --services
}

ps() {
    set -x
    [ -n "$1" ] && export FILTER="--filter name=$1"
    $DOCKERCMD ps $FILTER
}

update() {
    stop
    echo "Updating RaceDB and PostgreSQL containers (if available)"
    $DOCKERCMD pull
}

#build() {
#    if [ ! -f "$COMPOSEFILE" ]; then
#        echo "ERROR: Command must be run from same directory as the $COMPOSEFILE file."
#        exit 1
#    fi
#    . .dockerdef
#    docker build -t $IMAGE:$TAG .
#}

#rebuild() {
#    if [ ! -f "$COMPOSEFILE" ]; then
#        echo "ERROR: Command must be run from same directory as the $COMPOSEFILE file."
#        exit 1
#    fi
#    . .dockerdef
#    docker build -t $IMAGE:$TAG --no-cache .
#}

cleanall() {
#    if [ ! -f "$COMPOSEFILE" ]; then
#        echo "ERROR: Command must be run from same directory as the $COMPOSEFILE file."
#        exit 1
#    fi
    echo -n "About to wipe all the RaceDB data and configuration!! Are you sure? THIS CANNOT BE UNDONE! (type YES): "
    read ENTRY
    if [ "$ENTRY" = "YES" ]; then
        stop
        
        RACEDBCONTAINERS=$(docker container list -a | grep racedb_app | awk '{ print $1 }')
        for container in $RACEDBCONTAINERS
        do
            echo "Removing container: $container"
            docker container rm -f $container
        done

        RACEDBIMAGES=$(docker image list | grep racedb | awk '{print $3}')
        for image in $RACEDBIMAGES
        do
            echo "Removing image: $image"
            docker image rm -f $image
        done

        VOLUMES=$(docker volume list | grep racedb | awk '{print $2}')
        for volume in $VOLUMES
        do
            echo "Removing RaceDB volume: $volume"
            docker volume rm $volume
        done

        NETWORKS=$(docker network list | grep racedb | awk '{print $2}')
        for network in $NETWORKS
        do
            echo "Removing RaceDB network: $network"
            docker network rm $network
        done

        if [ -f RaceDB.sqlite3 ]; then
            echo "Removed old RaceDB.sqlite3"
            rm -f RaceDB.sqlite3
        fi
    else
        echo "Clean cancelled"
    fi
}


restoredata()
{
    filename=$1

    if [ -n "${filename}" ] ; then

        #if [ !  -f "racedb-data/${filename}" ];then
        #    echo "racedb-data/${filename} does not exist"
        #    exit 1
        #fi
        echo "Importing racedb-data/${filename}..."

        set -x
        $DOCKERCMD exec $RACEDB python3 /RaceDB/manage.py flush 
        $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py loaddata /racedb-data/${filename}
    fi
}

backupdata()
{
    filename=$1

    if [ -z "$filename" ]; then
        DATE=$(date +%Y%m%d-%H%M%S)
        filename="racedb-export-${DATE}.json"
    fi

    echo "Backing up in $RACEDB:/racedb-data/${filename}... "
    set -x
    $DOCKERCMD exec $RACEDB python3 /RaceDB/manage.py dumpdata core --indent 2 --output /racedb-data/${filename}
    set +x
    echo "Export saved to racedb-data/${filename}..."
}


importdata()
{
    filename=$1

    if [ "-" = "${filename}" ]; then
        echo "Importing from <stdin>"
        set -x
        $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py flush --no-input
        $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py loaddata --format=json -

    elif [ -n "${filename}" ] ; then

        #if [ !  -f "racedb-data/${filename}" ];then
        #    echo "racedb-data/${filename} does not exist"
        #    exit 1
        #fi
        echo "Importing racedb-data/${filename}..."

        set -x
        $DOCKERCMD exec $RACEDB python3 /RaceDB/manage.py flush 
        cat ${filename} | $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py loaddata --format=json -
    fi
}

exportdata()
{
set -x
    filename=$1

    if [ "-" = "${filename}" ]; then
        echo "Exporting to <stdout>"
        set -x
        $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py dumpdata core --indent 2 

    else
        if [ -z "$filename" ]; then
            DATE=$(date +%Y%m%d-%H%M%S)
            filename="${HOSTNAME}-racedb-export-${DATE}.json"
        fi
        echo "Exporting from $RACEDB to ${filename}..."
        set -x
        ( $DOCKERCMD exec -T $RACEDB python3 /RaceDB/manage.py dumpdata core --indent 2 ) > ${filename}
        set +x
        echo "Export saved to ${filename}..."
    fi
}

reader() {
    READER=$1
    if [ -z "$READER" ]; then
        echo "You must specify the reader name or ip"
        exit 1
    fi
    if (echo "$READER" | grep -Eq "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"); then
        READER_IP=$READER
    elif (echo "$READER" | grep -Eq ".*\.local$"); then
        if [ "$(uname -s)" == "Darwin" ]; then
            READER_IP=$(ping -c 1 "$READER" | grep from | awk '{print $4}' | awk -F':' '{print $1}')
        else
            READER_IP=$(avahi-resolve -n "$READER" | awk '{print $2}')
        fi
    else
        READER_IP=$(host $READER | awk '{print $4}')
        if [ "$READER_IP" == "found:" ]; then
            echo "READER ip not found"
            exit 1
        fi
    fi
    if [ -z "$READER_IP" ];then
        echo "Error finding reader IP"
        exit 1
    fi
    echo "Reader IP is $READER_IP"
    grep -v RFID_READER_HOST racedb.env > racedb.env.tmp.$$
    echo "RFID_READER_HOST=$READER_IP" >> racedb.env.tmp.$$
    cp racedb.env racedb.env.bak
    mv racedb.env.tmp.$$ racedb.env
    echo "racedb.env updated"
}


usage() {
    DATE=$(date +%Y%m%d-%H%M%S)


    if [ ${POSTGRESQL_RACEDB_RUNNING} -eq 1 ] ; then
        stderr 
        stderr "RaceDB Containers: ${ROLE^^} - RUNNING"
        stderr "${ARG0} Commands:"
        stderr "    help                - display usage"
        case "${ROLE}" in
        primary)
            stderr "    restart             - stop and restart RaceDB as PRIMARY Servers"
            stderr "    stop                - stop RaceDB as PRIMARY Servers"
            stderr "    dumpall             - do a pg_dumpall backup"
            ;;
        hot_standby)
            stderr "    failover            - enable HOT-STANDBY FAILOVER (with immediate effect, no restart"
            stderr "    promote             - promote HOT-STANDBY to PRIMARY (will restart)"
            stderr "    restart             - stop and restart RaceDB as HOT-STANDBY FAILOVER Server"
            stderr "    stop                - stop RaceDB"
            stderr "    dumpall             - do a pg_dumpall backup"
            ;;
        failover)
            stderr "    fallback            - change FAILOVER back to HOT-STANDBY (will restart)"
            stderr "    promote             - promote HOT-STANDBY to PRIMARY"
            stderr "    restart             - stop and restart RaceDB as FAILOVER Servers"
            stderr "    stop                - stop RaceDB "
            ;;
        *) ;;
        esac
    else
        stderr 
        stderr "RaceDB Containers NOT RUNNING - last role was ${ROLE^^}"
        stderr "${ARG0} Commands:"
        stderr "    help              - display usage"
        stderr
        case "${ROLE}" in
        primary | restore_* )
            stderr "  Primary"
            stderr "    restore_sql - restore from local sql backup and start"
            stderr "    restore_local - restore from local filesystem backup and start"
            stderr "    restore_host - restore from another host and start"
            stderr "    standby - start as HOT-STANDBY"
            ;;
        hot_standby | standby)
            stderr "  Standby"
            stderr "    start - start as HOT-STANDBY"
            stderr "    failover - start HOT-STANDBY server in FAILOVER mode"
            stderr "    primary - start as primary using current database"
            ;;
        failover)
            stderr "  Standby-Failover"
            stderr "    start"
            stderr "    standby - start as hot_standby"
            stderr "    primary - start as primary using current database"
            ;;
        *)
            stderr "  Role not set"
            stderr "    standby"
            stderr "    primary"

        esac
    fi

    
    return
    
    stderr "  Manage containers"
    stderr "    pull              - pull newer images from docker hub"
    stderr "    run               - start the racedb containers"
    stderr "    stop              - stop the racedb containers"
    stderr "    restart           - stop and restart the racedb containers"
    stderr "    ps                - list running racedb containers"
    stderr "    logs name         - show the named racedb container log"
    stderr "    flogs name        - show the named racedb container log and display continuously"
    stderr
    stderr "  Access containers"
    stderr "    bash name         - run bash shell in named running container"
    stderr
    stderr "  RaceDB Manage"
    stderr "    manage name       - run manage.py in named running container, passes additional args to manage"
    stderr
    stderr "  Backup and Restore RaceDB in container"
    stderr "    backup            - export database to $RACEDB/racedb-data/racedb-export-$DATE.json"
    stderr "    backup filename   - export database to $RACEDB/racedb-data/filename"
    stderr "    restore filename  - restore database from $RACEDB/racedb-data/filename"
    stderr
    stderr "  Export and Import RaceDB to files on $(hostname)"
    stderr "    export            - export database to /racedb-data/racedb-export-$DATE.json"
    stderr "    export filename   - export database to filename"
    stderr "    export -          - export database to <stdout> in json file format"
    stderr "    import filename   - import new database from $RACEDB/racedb-data/filename"
    stderr "    import -          - import new database from <stdin> json file format"
    stderr
    stderr "    reader ip|name    - updates racedb.env with the reader ip" 
    stderr
    stderr "Use a webbrowser to login to RaceDB: http://localhost"
    stderr 
}

[ $# -eq 0 ] && usage && exit

CMD=$1
shift



case $CMD in
    "help") usage; exit 0 ;;
    "config") checkconfig; exit 0 ;;
    "config") checkconfig; exit 0 ;;
    "logs" | "log") logs ;;
    *) ;;
esac

if [ ${POSTGRESQL_RACEDB_RUNNING} -eq 1 ] ; then

    stderr "RaceDB Containers running - ${ROLE}"
    case $CMD in
        stop) stop; exit 0 ;;
        restart) restart; exit 0 ;;
        *) ;;
    esac

    case "${ROLE}-${CMD}" in
        *-restore_sql ) primary_restore_sql "${*}"; start;;
        hot_standby-failover) failover ; exit 0;;
        failover-fallback) stop; fallback; start ; exit 0;;
        failover-dumpall | primary-dumpall) dumpall; exit 0;;
        failover-promote) stop; setrole primary; start; exit 0;;
        *) ;;
    esac

    case $CMD in
        hot_standby | standby | primary ) stderr "Containers running cannot change role, stop first";;
        *);;
    esac

else
    stderr "RaceDB Containers NOT RUNNING - ${ROLE}"
    case $CMD in
        start | run) start; exit 0 ;;
        restart) restart; exit 0 ;;
        primary) setrole primary; start; exit 0 ;;
        hot_standby | standby) setrole hot_standby; start; exit 0 ;;
        restore) setrole restore; erase_db; start; exit 0 ;;
        *) ;;
    esac
    stderr "ROLE: $ROLE CMD: $CMD"
    set -x
    case "${ROLE}-${CMD}" in
        #*-restore_sql ) primary_restore_sql "${*}"; start;;
        #primary-restore_local | hot_standby-restore_local) primary_restore_local "${*}"; start;;
        #primary-restore_host | hot_standby-restore_host) primary_restore_host "${*}"; start;;
        hot_standby-failover | standby-failover) failover; exit 0;;
        failover-fallback) fallback; exit 0;;
        failover-primary | failover-promote) setrole primary; exit 0;;
    esac
fi
exit

ROLECMD="$ROLE-$CMD"

stderr ROLE-CMD: $ROLECMD

set -x
case "$ROLECMD" in
    primary-restore_local) ;;
    primary-restore_remote) ;;
    primary-standby) ;;
    hot_standby-failover | standby-failover) ;;
    hot_standby-promote | standby-promote) ;;
    failover-demote) ;;
    failover-primary) ;;
    "standby-failover-fallback") fallback ;;
    *) echo "Unknown: \"$ROLECMD\"" 
esac
exit


#case "$CMD" in
#    "failover") failover ;;
#    "fallback") fallback ;;
#    #"master") master
#    #    ;;
#    #"standby") standby
#    #    ;;
#    "pull") pull ;;
#    "run" | "start") run ;;
#    "restart") restart ;;
#    "bash") bash ;;
#    "update") update ;;
#    "logs" | "log") logs ;;
#    "flogs" | "flog") flogs ;;
#    "stop") stop ;;
#    "images") images ;;
#    "services") services ;;
#    "ps") ps $1 ;;
#    "manage") manage $@ ;;
#    "backup") backupdata $@ ;;
#    "restore") restoredata $@ ;;
#    "import") importdata $@ ;;
#    "export") exportdata $@ ;;
#    "clean") cleanall ;;
#    "build") build
#        ;;
#    "rebuild") build
#        ;;
#    "reader") reader $@ ;;
#    *) echo "Unknown command."
#       usage
#       ;;
#esac


        
