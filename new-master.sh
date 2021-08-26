#!/bin/bash
set -x
./manage.sh stop
sudo rm -rfv postgresql-data/*
./manage.sh start
docker exec -it racedb_8080 python3 /RaceDB/manage.py flush
docker exec -it racedb_8080 python3 /RaceDB/manage.py loaddata /racedb-data/test.json
./manage.sh restart

