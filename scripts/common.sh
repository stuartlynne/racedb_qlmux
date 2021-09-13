#
# vim: noexpandtab tabstop=4 shiftwidth=4 textwidth=0
#
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

mkdir -v -p db/{primary,standby}/{data,lib,run}

VARDATA="./db/${ROLE}/data"
VARLIB="./db/${ROLE}/lib"
VARRUN="./db/${ROLE}/run"
TRIGGERPATH="./db/standby/lib/trigger_file_standby_to_failover"

#export PRIMARY_HOST=""
#export STANDBY_HOST=""

. ./docker.env

RUNNING() {
	if [ $1 -eq 1 ] ; then echo "RUNNING"; else echo "NOT RUNNING"; fi
}

./scripts/container_running.sh postgresql_racedb_primary && POSTGRESQL_RACEDB_PRIMARY_RUNNING=1 || POSTGRESQL_RACEDB_PRIMARY_RUNNING=0
./scripts/container_running.sh postgresql_racedb_standby && POSTGRESQL_RACEDB_STANDBY_RUNNING=1 || POSTGRESQL_RACEDB_STANDBY_RUNNING=0
    
stderr "RaceDB Containers [PRIMARY] $(RUNNING $POSTGRESQL_RACEDB_PRIMARY_RUNNING)"
stderr "RaceDB Containers [STANDBY] $(RUNNING $POSTGRESQL_RACEDB_STANDBY_RUNNING)"

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

DOCKERCMD="docker-compose ${YMLLIST}"

stop() {
    echo "Stopping RaceDB Container set..."
    set -x
    $DOCKERCMD stop
}

start() {
    echo "Starting RaceDB Container set... ${ROLE}"
    set -x
    $DOCKERCMD up -d
}

restart() {
    stop
    sleep 2
    start
    $DOCKERCMD restart
}

CMD=$1
shift


