#!/bin/bash
#set -x

ARG0=$(basename $0)

RACEDB=racedb_8080
PRIMARY=(  
    ./postgresql/docker-compose.yml 
    ./racedb/docker-compose.yml 
    ./racedb/docker-compose-network.yml 
#    ./qllabels-qlmuxd/docker-compose.yml
#    ./racedb/docker-compose-8080.yml 
#    ./racedb/docker-compose-8081.yml 
    )

SECONDARY=(  
    ./postgresql/docker-compose.yml 
    )





function stderr() {
    echo "${*}" 1>&2
}


for i in "${PRIMARY[@]}"; do
    [ -e "${i}" ] && continue
    stderr
    stderr "${ARG0}: cannot find ${i}"
    stderr
    exit 1
done

rollusage() {
    stderr
    stderr "Postgress roll is not set."
    stderr 
    stderr "Use ./manage.sh primary|secondary to set database roll."
    stderr 
    exit 1
}

if [ ! -f "postgresql/postgresql.env" ] ; then

    if [ $# -eq 0 ] ; then
        rollusage
    fi

    CMD=$1
    shift
    case $CMD in
        "help") usage
            ;;
        "primary")
            cp -v postgresql/primary.env postgresql/postgresql.env
            ;;
        "secondary")
            cp -v postgresql/primary.env postgresql/postgresql.env
            ;;
        *)
            rollusage
            exit 1
            ;;
    esac
    exit 0
else
    . ./postgresql/postgresql.env
fi

if [ -z "${POSTGRESSROLE}"  -o "${POSTGRESSROLE}" = "n" ] ; then
    stderr "Postgres Server Role: Primary"
    CMDLIST=$(for i in "${PRIMARY[@]}"; do echo -f "$i"; done)
elif [ -n "${POSTGRESSROLE}"  -o "${POSTGRESSROLE}" = "y" ] ; then
    stderr "Postgres Server Role: Secondary"
    CMDLIST=$(for i in "${SECONDARY[@]}"; do echo -f "$i"; done)
else
    stderr "Postgres Server Role: unknown"
    rollusage

fi

DOCKERCMD="docker-compose ${CMDLIST}"

checkconfig() {
    stderr
    stderr PRIMARY: ${PRIMARY[@]}
    stderr SECONDARY: ${SECONDARY[@]}
    stderr CMDLIST: $CMDLIST
    stderr DOCKERCMD: $DOCKERCMD
    
    stderr 
    stderr RaceDB Container Configuration
    for i in "${PRIMARY[@]}"; do
        stderr $i
    done
    stderr
    stderr Default RaceDB Service: $RACEDB
    stderr

}


restart() {
    stop
    sleep 2
    run
}

pull() {
    echo "Starting RaceDB Container set..."
    set -x
    $DOCKERCMD pull
}

run() {
    echo "Starting RaceDB Container set..."
    set -x
    $DOCKERCMD up -d
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

stop() {
    echo "Stopping RaceDB Container set..."
    $DOCKERCMD stop
}

images() {
    $DOCKERCMD images 
}

services() {
    $DOCKERCMD ps --services
}

ps() {
    $DOCKERCMD ps
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
    stderr "${ARG0} Commands:"
    stderr "    help              - display usage"
    stderr
    stderr "  Configure Primary or Secondary"
    stderr "    Primary Server"
    stderr "    Secondary Standby"
    stderr
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
    "help") usage
        ;;
    "config") checkconfig
        ;;
    "pull") pull
        ;;
    "run" | "start") run
        ;;
    "restart") restart
        ;;
    "bash") bash
        ;;
    "update") update
        ;;
    "logs" | "log") logs
        ;;
    "flogs" | "flog") flogs
        ;;
    "stop") stop
        ;;
    "images") images
        ;;
    "services") services
        ;;
    "ps") ps
        ;;
    "manage") manage $@
        ;;
    "backup") backupdata $@
        ;;
    "restore") restoredata $@
        ;;
    "import") importdata $@
        ;;
    "export") exportdata $@
        ;;
    "clean") cleanall
        ;;
#    "build") build
#        ;;
#    "rebuild") build
#        ;;
    "reader") reader $@
        ;;
    *) echo "Unknown command."
       usage
       ;;
esac


        
