# racedb/_qlmux/racedb\_qllabels container

## Overview
This container is set up to use:
  - an lpr script to forward labels for printing to the qlmux\_proxy container
  - a rfidproxy for printing and RFID using the qlmux\_proxy container. 
  - support using traefik for an https proxy 

This file is adapted from the RaceDB docker-compose.yml file. The main differences is
that it uses a private image of the RaceDB container that includes the qllabels. See
the Dockerfile in this directory for more information.

To use this file, you need to set the following environment variables in a .env file:
```
  RACEDB_PORT=8000
  RACEDB_HOSTNAME=racedb.local
  RFID_READER_HOST=127.0.0.1
  RFID_TRANSMIT_POWER=40
  RFID_RECEIVER_SENSITIVITY=20
  CSRF_TRUSTED_ORIGINS=https://racedb.example.com
```
N.b. The TRANSMIT\_POWER and RECEIVER\_SENSITIVITY are for the Impinj reader and should be set to the values for your reader
and the RFID wands in use.



## csrf.py

This is a simple script in the Dockerfile to append the CSRF\_TRUSTED\_ORIGINS to the settings.py file.

The CSRF\_TRUSTED\_ORIGINS needs to be set in the *docker.env* file.

The script is run when the private RaceDB image is built by docker.

```
#!/bin/sh
#
echo CSRF_TRUSTED_ORIGINS = [\"${CSRF_TRUSTED_ORIGINS}\", ]  >> /RaceDB/RaceDB/settings.py
```

See DockerFile:
```
# Append CSRF_TRUSTED_ORIGINS to RaceDB	Settings, 
# doing it in csrf.sh to get the quoting right.
COPY csrf.sh .
RUN /csrf.sh
```

## Printer Configuration in RaceDB

*RaceDB* needs to be configured to send print data to the qlmux\_proxy application. This is done by
configuring the LP print command in Systeminfo\->Printer Configuration. 

A simple *lpr* script is installed that uses ssh to send the print data to the qlmux\_proxy container.
```
#!/bin/sh
ssh -p 9122 -o StrictHostKeyChecking=no racedb@172.17.0.1 qllabels ${1} 
```

N.b. 172.17.0.1 is the default address of the host machine on the docker0 network.


### Table vs Kiosk
- Table - RaceDB should be configured to use 127.0.0.1
- Kiosk - RaceDB should be configured to use 127.0.0.2

N.b. The Table vs Kiosk is a convention, there is no difference in the qlmux\_proxy application and this could just be two
tables or kiosks.

## Import of existing data

To import an existing JSON data file:
```
cd racedb_ssh
cp racedb-backup-20240830-102354.json racedb_data/racedb-import.json
make down up logs
```


## Backup
The database is NOT backed up to the */racedb-data/* directory every time the container is started.

This can be disabled by removing this file: 
```
    ./racedb-data/.NOBACKUP
```

