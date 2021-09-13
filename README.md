# racedb\_qlmuxd
## Sun Sep 12 16:29:56 PDT 2021 
## stuart.lynne@gmail.com

The *racedb\_qlmuxd* git archive implements management scripts to support running RaceDB, Postgresql
and qlmuxd in containers.

The primary features:
1. Implementation of *PRIMARY* and *STANDBY* container sets to support hot-standby backup on a second hardware system
2. Support for *qllabels* which converts RaceDB label PDF files to Brother Raster files for printing on *QL* label printers
3. Support for *qlmuxd* which supports multiplexing label printing to target sets of *QL* label printers with failover support.


## Installation

Clone the archive on two Linux based laptops:

```
    git clone https://github.com/stuartlynne/racedb_qlmuxd.git

```

Edit the *docker.env* file to set the required configuration:
```
#
CONTAINER_YML_LIST=(
    ./postgresql/docker-compose.yml
    ./racedb/docker-compose.yml
    ./qllabels-qlmuxd/docker-compose.yml
    )

export PRIMARY_HOST=""
export STANDBY_HOST=""

export DEFAULT_PRIMARY_HOST=192.168.40.17
export DEFAULT_STANDBY_HOST=192.168.40.16

# Impinj R1000 with Lilly 5dBi PCB UHF RFID Patch antenna wands
RFID_READER_HOST_8080=192.168.40.101
RFID_TRANSMIT_POWER_8080=40
RFID_RECEIVER_SENSITIVITY_8080=5

```
This needs to be copied into the top level of the git archive on both systems.

On the *PRIMARY* system:
```
./primary.sh start
```

On the *STANDBY* system:
```
./standby.sh start
```


### Use
The docker containers should start automatically when the laptops are turned on.

Registration laptops / chromebooks should connect to port 8080 using the ip address of the PRIMARY host.

### Failure

If the PRIMARY host fails, disconnect it from the network. On the STANDBY host:
```
./standby.sh failover
```




## Containers

Each of these can be started to act as the *PRIMARY* or *STANDBY* container set. 

1. postgresql\_racedb
2. racedb\_8080
3. qllabels
4. qlmuxd

N.B. It is not possible to run both the PRIMARY and STANDBY container sets on the same host computer at the same time.


### postgresql\_racedb

This implements the *postgresql* database server. 

When started as the PRIMARY server it operates normally to service database requests from the PRIMARY RaceDB server. There are
options to restore the database from a local backup or remote host prior to the server starting.

When started as the STANDBY server it first replicates the database from the PRIMARY postgresql server then continues
to receive WAL records from the PRIMARY as changes are made to the PRIMARY database.

If the PRIMARY container stack fails the STANDBY postgresql server is trigged into acting in *FALLOVER* mode. It will then allow
queries from the SECONDARY RaceDB server (which will also start when the trigger to FALLOVER is done.)


### racedb\_8080

This implements *RaceDB*. When started in PRIMARY mode it starts normally.

When started in STANDBY mode RaceDB will wait for the FAILOVER signal and for *postgresql* to become available
and then will start normal operation.


### qllabels
The *qllabels* container set maintains an open *ssh* port (on the internal racedb private network within docker.)

Set in RaceDB/systeminfo:

```
ssh racedb@qllabels.local QLLABELS.py $1
```

### qlmuxd
The *qlmuxd* container set maintains a set of open *TCP* ports (9100..9104) in the racedb private network 
(internal to docker) that will accept data to be sent
to one of the pre-defined printer queues. The data must be *Brother* raster format. Typical implementation:

- two sets of QL710W printers for small frame/shoulder numbers
- two QL1050N printers for large bib numbers

*qlmuxd* will send the labels to the specific printer queue associated with the registration desk position (antenna port number.)
If the required printer is not available (busy, out of labels, lid open) it will use the designated backup printer.

*qlmuxd\_docker* contains scripts to use *RaceDB* with *qlmuxd* in containers.

Specifically it contains the *racedb.sh* script and updated *docker-compose.yml*
files from the *RaceDB* git archive that allow *RaceDB* to be used, updated,
the database imported and exported etc.

Additionally it shows how to bring up multiple copies of *RaceDB* so that
multiple *RFID* readers can be used. E.g. to implement a second registration
table or remote check-in kiosks.

*qlmuxd* is a Brother QL printer spooler that *RaceDB* can use to print frame
and bib numbers on small and large labels.





## #########################33



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

These implement one or more *RaceDB* services. Each can be configured to use a different *RFID_READER_HOST*.


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


## 


##### vim: textwidth=0

