# qlmuxd_docker
## Tue Aug 17 15:13:38 PDT 2021
## stuart.lynne@gmail.com


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


