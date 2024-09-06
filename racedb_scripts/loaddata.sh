#!/bin/bash

[ $# -eq 1 ] || (echo "usage: loaddata.sh racedb_json.gz"; exit 1)
set -x
CONTAINER=$(basename $(/bin/pwd))
echo $CONTAINER

#           docker exec -i ${CONTAINER} python3 /RaceDB/manage.py loaddata --format=json -
gunzip < $1 | docker exec -i ${CONTAINER} python3 /RaceDB/manage.py loaddata --format=json -
