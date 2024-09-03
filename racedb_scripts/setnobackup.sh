#!/bin/bash
#
set -x
echo ".nobackup" > ./racedb-data/.gitignore
touch ./racedb-data/.nobackup
git add ./racedb-data/.gitignore
git commit -m 'Add .nobackup to ./racedb-data/.gitignore' racedb-data/.gitignore


