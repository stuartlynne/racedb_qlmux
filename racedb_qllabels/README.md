# RaceDB QLLabels

## Overview
This container is set up to use:
  - a proxy for printing and RFID using the qlmux_proxy container. 
  - support using traefik for an https proxy 

qllabels supports printing frame and bib labels using Brother QL printers 
by sending the label data to another container running qlmux_proxy. 

qlmux_proxy is a server that supports printing on a pool of Brother QL Printers and
can act as a proxy to an Impinj RFID reader. It uses SNMP to discover both the printers
and the RFID reader, removing the need to manually configure the IP addresses of the
RFID reader in RaceDB.

See the qlmux_proxy container definition in this project for more information.

See the traifik_racedb container definition is this project for more information on
how to set of the https proxy. It is optional, and requires that you have a DNS
provider that supports LetsEncrypt DNS-01 challenges using an API key.

This file is adapted from the RaceDB docker-compose.yml file. The main differences is
that it uses a private image of the RaceDB container that includes the qllabels. See
the Dockerfile in this directory for more information.

To use this file, you need to set the following environment variables in a .env file:
  RACEDB_PORT=8000
  RACEDB_HOSTNAME=racedb.local
  RFID_READER_HOST=127.0.0.1
  RFID_TRANSMIT_POWER=40
  RFID_RECEIVER_SENSITIVITY=20
  CSRF_TRUSTED_ORIGINS=https://racedb.example.com



## Backup
By default the database is backed up to the */racedb-data/* directory every time the container is started.

This can be disabled by setting creating a file:
```
    */racedb-data/.nobackup*
```

## csrf.sh

This is a simple script in the Dockerfile to append the CSRF_TRUSTED_ORIGINS to the settings.py file.

The CSRF_TRUSTED_ORIGINS needs to be set in the *docker.env* file.

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


