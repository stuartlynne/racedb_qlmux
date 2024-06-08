#!/bin/bash
#
DATE=$(date +%Y%m%d-%H%M%S)
CONTAINER=$(basename $(/bin/pwd))
filename=$1
if [ -z "$filename" ]; then
    filename="${HOSTNAME}-${CONTAINER}-${DATE}.json.gz"
fi          
echo "Exporting from ${CONTAINER} to ${filename}..."
set -x
( set -x; docker exec ${CONTAINER} python3 /RaceDB/manage.py dumpdata core --indent 2 ) | gzip > ${filename}
set +x
echo "Export saved to ${filename}..."

