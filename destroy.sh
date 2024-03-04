#!/bin/bash


containers="racedb_8080_primary qllabels_qlmuxd qlmuxd postgresql_racedb_primary"

set -x
docker container stop $containers
docker container rm $containers --force --volumes 

rm -rfv db

