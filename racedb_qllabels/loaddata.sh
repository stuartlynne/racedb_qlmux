#!/bin/bash

set -x

gzip < $1 | docker exec -i racedb_8080_primary python3 /RaceDB/manage.py loaddata --format=json -
