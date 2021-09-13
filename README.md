# racedb\_qlmuxd
## Sun Sep 12 16:29:56 PDT 2021 
## stuart.lynne@gmail.com

The *racedb\_qlmuxd* git archive implements management scripts to support running RaceDB.

The primary features:
1. Implementation of *PRIMARY* and *STANDBY* container sets to support hot-standby backup on a second host system
2. Support for *qllabels* which converts RaceDB label PDF files to Brother Raster files for printing on *QL* label printers
3. Support for *qlmuxd* which supports multiplexing label printing to target sets of *QL* label printers with failover support.


## Containers

Each of these can be started to act as the *PRIMARY* or *STANDBY* container set. 

1. postgresql_racedb
2. racedb_8080
3. qllabels
4. qlmuxd

N.B. It is not possible to run both the PRIMARY and STANDBY container sets on the same host computer at the same time.


## postgresql_racedb

This implements the *postgresql* database server. 

When started as the PRIMARY server it operates normally to service database requests from the PRIMARY RaceDB server. There are
options to restore the database from a local backup or remote host prior to the server starting.

When started as the STANDBY server it first replicates the database from the PRIMARY postgresql server then continues
to receive WAL records from the PRIMARY as changes are made to the PRIMARY database.

If the PRIMARY container stack fails the STANDBY postgresql server is trigged into acting in *FALLOVER* mode. It will then allow
queries from the SECONDARY RaceDB server (which will also start when the trigger to FALLOVER is done.)


## racedb_8080

This implements *RaceDB*. When started in PRIMARY mode it starts normally.

When started in STANDBY mode RaceDB will wait for the FAILOVER signal and for *postgresql* to become available
and then will start normal operation.


## qllabels
The *qllabels* container set maintains an open *ssh* port (on the internal racedb private network within docker.)

Set in RaceDB/systeminfo:

```
ssh racedb@qllabels.local QLLABELS.py $1
```


## qlmuxd
The *qlmuxd* container set maintains a set of open *TCP* ports (9100..9104) in the racedb private network 
(internal to docker) that will accept data to be sent
to one of the pre-defined printer queues. The data must be *Brother* raster format. Typical implementation:

- two sets of QL710W printers for small frame/shoulder numbers
- two QL1050N printers for large bib numbers

*qlmuxd* will send the labels to the specific printer queue associated with the registration desk position (antenna port number.)
If the required printer is not available (busy, out of labels, lid open) it will use the designated backup printer.






*qlmuxd_docker* contains scripts to use *RaceDB* with *qlmuxd* in containers.

Specifically it contains the *racedb.sh* script and updated *docker-compose.yml*
files from the *RaceDB* git archive that allow *RaceDB* to be used, updated,
the database imported and exported etc.

Additionally it shows how to bring up multiple copies of *RaceDB* so that
multiple *RFID* readers can be used. E.g. to implement a second registration
table or remote check-in kiosks.

*qlmuxd* is a Brother QL printer spooler that *RaceDB* can use to print frame
and bib numbers on small and large labels.

## racedb.sh configurtion

See the first few lines of *racedb.sh*:

```
PRIMARY="docker-compose 
    -f ./postgres/docker-compose-primary.yml 
    -f ./racedb/docker-compose-8080.yml 
    -f ./racedb/docker-compose-8081.yml 
    -f ./qllabels-qlmuxd/docker-compose.yml"
```

This specifies which *docker-compose.yml* files your use of *RaceDB* requires.

## docker-racedb/docker-compose-808N.yml

These implement one or more *RaceDB* services.

These are copies of the original docker-compse.yml files from *RaceDB* with
the *postgres* portion removed, and each specifying a different host port
to use, and a different *racedb-808N.env* file. The *.env* file contains
the RFID reader configuration.

## postgres/docker-compose-primary.yml

This is the *postgres* service configuration.

## docker-qllabels-qlmuxd/docker-compose.yml

This implements two services:

- qllabels\_qlmuxd
- qlmuxd

*RaceDB* will use ssh to send labels to the qllabels_qlmuxd service, which
in turn will convert the PDF file into Brother Raster data which it will
send to the *qlmuxd* service. 

The *qlmuxd* service will in turn send the raster data to the appropriate
Brother QL printer.

## docker-qllabels-direct/dockger-compose.yml

This implements a single service:

- qllabels\_qlmuxd

*RaceDB* will use ssh to send labels to the qllabels_qlmuxd service, which
in turn will convert the PDF file into Brother Raster data which it will
send to directly to the Brother Printers.

*N.B. This is only appropriate when the Brother QL printers are only
used by a single registration clerk. Multiple people printing to a
printer will result in overlapping printouts.*


