# racedb\_qlmuxd
## Tue 27 Feb 2024 07:40:50 PM PST
## Sun Sep 12 16:29:56 PDT 2021 
## stuart.lynne@gmail.com

This *racedb\_qlmuxd* git archive implements management scripts to support running RaceDB, Postgresql
and qlmuxd in containers on a Linux system.

The primary features:
1. Implementation of *PRIMARY* and *STANDBY* container sets to support hot-standby backup on a second hardware system
2. Support for *qllabels* which supports fast conversion of RaceDB label PDF files to 
Brother Raster files for printing on Brother *QL* label printers
3. Support for *qlmuxd* which supports multiplexing label printing to target sets of *QL* label printers with failover support.
4. Reduction of the number of volunteers required to do registration at an event.

This setup is a containerized version of what was used to support thirty plus events per year from 2017-2019,
ranging in size from 80 to 600 entries.

QLMuxd allowed for using three small label printers and two large label printers to support:
- Frame Plate numbers
- Arm band numbers
- BIB numbers

QLMUxd automatically detects common printer faults (paper jam, paper out, lid open) and 
sends jobs to the backup for the printer.

The use of low cost RFID tags meant racers could keep them. And if they did another event RaceDB
could quickly find them. 

For large events four registration stations and two kiosks were used. Roughly 75% of the racers
were pre-registered but RaceDB allowed for fast registration of day-of entries. 

Kiosks allowed pre-registered entrants that already had their (previously issued) BIB and Frame plate to 
self-scan their tag to verify that they were properly registered. 

Note that this had the side-effect
of verifying that they had a Frame Plate (aka RFID tag) that was properly programmed, readable and 
correctly associated with them. I.e. 99% of the way to correctly getting them into CrossMgr
for the event. Effectively as long as they don't lose their tag between checkin and the event
they will be seen by the timing system.

Roughly:
- confirming a registration with existing tag - 10-15 seconds
- confirming a registration with lookup, and then creation of new tag - less than 1 minute
- adding a new rider from scratch - less then 2 minutes
- adding a registration with existing tag - 30-45 seconds

Our spring series events would have between 100-150 entries, and all day of event
registration was generally completed with two or three stations in less than one hour.

### BIB and Frame Numbers

Printing BIB and Frame numbers at the event is a big win. Effectively this reduces 
the number of volunteers required. No need to "assign" numbers from a pool of available 
numbers and then find a pre-printed frame plate and BIB.

Printing on-demand takes a few seconds (hit print, hand the entrant his new RFID tag frameplate and a blank BIB).




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
sudo ./primary.sh start
```

On the *STANDBY* system:
```
sudo ./standby.sh start
```

### SystemInfo

The initial default configuration for RaceDB needs to be changed to support
printing labels via the QLLabel program. 

To allow quick reset of RaceDB including some SystemInfo defaults the systeminfo.json
file can be loaded. 

```
sudo ./primary.sh systeminfo   # optional to set SystemInfo
```

The provided sample changes the label options to be correct for the qllabels container.

```
    "print_tag_option": 1,
    "server_print_tag_cmd": "ssh -o StrictHostKeyChecking=no racedb@qllabels.local QLLABELS.py \"$1\"",
```

### SSH Fix



### Load Data

If you have a backup copy of the RaceDB database as a JSON file that can be loaded
with:
```
    ./primary.sh loaddata racedb-backup.json
```

*N.b. That will replace the entire RaceDB database!*

### Dump Data

A backup copy of the RaceDB data as a JSON file can be created with:
```
    ./primary.sh dumpdata
```


### Use
The docker containers should start automatically when the laptops are turned on.

Registration laptops / chromebooks should connect to port 8080 using the ip address of the PRIMARY host.

### Failure

If the PRIMARY host fails, disconnect it from the network. On the STANDBY host:
```
sudo ./standby.sh failover
```




## Containers


### RaceDB:

1. postgresql\_racedb
2. racedb\_8080

Each of these can be started to act as the *PRIMARY* or *STANDBY* container set. 
N.B. It is not possible to run both the PRIMARY and STANDBY container sets on the same host computer at the same time.




#### postgresql\_racedb

This implements the *postgresql* database server. 

When started as the PRIMARY server it operates normally to service database requests from the PRIMARY RaceDB server. There are
options to restore the database from a local backup or remote host prior to the server starting.

When started as the STANDBY server it first replicates the database from the PRIMARY postgresql server then continues
to receive WAL records from the PRIMARY as changes are made to the PRIMARY database.

If the PRIMARY container stack fails the STANDBY postgresql server is trigged into acting in *FALLOVER* mode. It will then allow
queries from the SECONDARY RaceDB server (which will also start when the trigger to FALLOVER is done.)


#### racedb\_8080

This implements *RaceDB*. When started in PRIMARY mode it starts normally.

When started in STANDBY mode RaceDB will wait for the FAILOVER signal and for *postgresql* to become available
and then will start normal operation.

### QLLabels and optional QLMuxd

1. qllabels-direct
2. qllabels-qlmuxd


#### qllabels-direct
The *qllabels* container set maintains an open *ssh* port (on the internal racedb private network within docker.)

Set in RaceDB/systeminfo:

```
ssh -o StrictHostKeyChecking=no racedb@qllabels.local QLLABELS.py $1
```

The script will convert the PDF label and send directly to the required label printer.

This is intended for use when only a single registration station is used. 

*If more than one label is printed from multiple stations they will not be correctly printed.*

To use add to the *CONTAINER_YML_LIST*:

```
CONTAINER_YML_LIST=(
    ./postgresql/docker-compose.yml
    ./racedb/docker-compose.yml
#    ./qllabels-qlmuxd/docker-compose.yml
    ./qllabels-direct/docker-compose.yml
#    ./racedb/docker-compose-8080.yml
#    ./racedb/docker-compose-8081.yml
    )

```


#### qllabels-qlmuxd

If multiple registration stations are in use this uses the *qlmux* spooler to capture the raster data
from the QLLabels script and direct it to the printers. This allows multiple "print jobs" to overlap
and be printed correctly.

This willcreate both a *qllabels* and *qlmuxd* container. The *qllabels* container is similar to what is created
above.

The *qlmuxd* container set maintains a set of open *TCP* ports (9100..9104) in the racedb private network 
(internal to docker) that will accept data to be sent
to one of the pre-defined printer queues. The data must be *Brother* raster format. Typical implementation:

- two sets of QL710W printers for small frame/shoulder numbers
- two QL1050N printers for large bib numbers

*qlmuxd* will send the labels to the specific printer queue associated with the registration desk position (antenna port number.)
If the required printer is not available (busy, out of labels, lid open) it will use the designated backup printer.

The *qlmux* git archive *qlmuxd\_docker* contains scripts to use *RaceDB* with *qlmuxd* in containers.

Specifically it contains the *racedb.sh* script and updated *docker-compose.yml*
files from the *RaceDB* git archive that allow *RaceDB* to be used, updated,
the database imported and exported etc.

Additionally it shows how to bring up multiple copies of *RaceDB* so that
multiple *RFID* readers can be used. E.g. to implement a second registration
table or remote check-in kiosks.

*qlmuxd* is a Brother QL printer spooler that *RaceDB* can use to print frame
and bib numbers on small and large labels.

To use add to the *CONTAINER_YML_LIST*:

```
CONTAINER_YML_LIST=(
    ./postgresql/docker-compose.yml
    ./racedb/docker-compose.yml
    ./qllabels-qlmuxd/docker-compose.yml
#    ./qllabels-direct/docker-compose.yml
#    ./racedb/docker-compose-8080.yml
#    ./racedb/docker-compose-8081.yml
    )

N.b. This *MUST* be done after the RaceDB and PostGres containers have been created and started
as they create the required network that the *qlmuxd* container will use.

```

Set in RaceDB/systeminfo:

```
ssh -o StrictHostKeyChecking=no racedb@qllabels.local QLLABELS.py $1
```




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

