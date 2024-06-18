#!/bin/bash

set -x
CONTAINER=$(basename $(/bin/pwd))
echo $CONTAINER

docker exec -i ${CONTAINER} python3 /RaceDB/manage.py loaddata --format=json -
#gzip < $1 | docker exec -i ${CONTAINER} python3 /RaceDB/manage.py loaddata --format=json -
