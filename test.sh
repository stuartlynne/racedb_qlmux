#!/bin/bash
set -x
./primary.sh start
#docker exec racedb_8080_primary apt-get update --fix-missing
#docker exec racedb_8080_primary apt-get install inetutils-ping

#sleep 5
#./primary.sh racedb_ssh
#exit
#./primary.sh loaddata racedb-json/test.json
#./primary.sh default
