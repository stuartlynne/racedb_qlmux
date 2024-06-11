# RaceDB QLMux 
## Mon Jun 10 12:01:08 PM PDT 2024
## stuart.lynne@gmail.com

## Overview

This is a revised version of the *racedb\_qlmuxd* git archive that implements management scripts to
support running RaceDB, Postgresql, qlmux_proxy and traefik in containers on a Linux system.

This is updated to use the newer *qlmux_proxy*, an upgraded version of qlmuxd that uses *SNMP*
to find and monitor the status of Brother QL printers and Impinj RFID readers.

This archive is suitable for use if you need a complete set of containers for RaceDB, Postgresql, qlmux_proxy and traefik.

If you want to add *qlmux_proxy* and *traefik* to an existing *RaceDB* installation you can use the
|[traefik\_racedb](https://github.com/stuartlynne/traefik\_racedb)| git archive. That is a 
configuration that can add a reverse proxy and the qlmux_proxy to an existing RaceDB installation.

Three container sets are created:

- racedb_qllabels (and postgresql)
- qlmux_proxy
- traefik_racedb

The racedb_qllabels container is a container that runs the RaceDB web server and application. It is the
standard RaceDB container with the addition of the *qllabels* script that allows RaceDB to send labels to

The *qlmux_proxy* container is a proxy that allows RaceDB to send labels to pool of Brother QL label printers.

The *traefik* container is a reverse proxy that allows access to the RaceDB web interface using *https*.
Note that the *traefik* container is configured to use a DNS challenge to obtain certificates from LetsEncrypt.

This allows for using a domain name to access the RaceDB web interface using *https* with a valid certificate.

Note that there is no requirement for any DNS setup for the domain names being used other than the base 
domain being owned by you and that you have an API key allowing access to your DNS provider. The container
needs outboud access to the internet to obtain the certificates. 

There is no need to have the domain
pointing to the server running the containers, although that can be done if you want to use the domain
name to access the server from the Internet.


## Background RFID

The use of low cost RFID tags meant racers could keep them. And if they did another event RaceDB
could quickly find them. 

Note that this had the side-effect
of verifying that they had a Frame Plate (aka RFID tag) that was properly programmed, readable and 
correctly associated with them. Specifically 99% of the way to correctly getting them into CrossMgr
for the event. Effectively as long as they don't lose their tag between check-in and the event
they will be seen by the timing system.

Roughly:
- confirming a registration with existing tag - 10-15 seconds
- confirming a registration with lookup, and then creation of new tag - less than 1 minute
- adding a new rider from scratch - less then 2 minutes
- adding a registration with existing tag - 30-45 seconds

Our spring series events would have between 100-200 entries, and all day of event
check-in and registration was completed with two or three stations in less than one hour.

For large events four registration stations and two kiosks were used. Roughly 75% of the racers
were pre-registered but RaceDB allowed for fast registration of day-of entries. 

Kiosks allowed pre-registered entrants that already had their (previously issued) BIB and Frame plate to 
self-scan their tag to verify that they were properly registered. 


## Background BIB and Frame Numbers

Printing BIB and Frame numbers at the event is a big win. Effectively this reduces 
the number of volunteers required. No need to "assign" numbers from a pool of available 
numbers and then find a pre-printed frame plate and BIB.

Printing on-demand takes a few seconds (hit print, hand the entrant his new RFID tag frameplate and a blank BIB).

Benefits:
- no need to pre-assign numbers
- no need to pre-print numbers
- no need to find the correct number in a box of pre-printed bibs
- lower number of bibs needed (no need to have a full set of bibs for each event)
- no need for volunteers to assign numbers and find bibs

## Installation

Clone the archive on a Linux based laptop:

```
    git clone https://github.com/stuartlynne/racedb_qlmux.git

```

Edit the *docker.env* file in each container directory to set the required configuration.

See the README.md in each container directory for details.

## [racedb\_qllabels](racedb_qllabels/README.md)
## [qlmux\_proxy](qlmux_proxy/README.md)
## [traefik\_racedb](traefik_racedb/README.md)
## [Docker usage](docker.md)
## [makefile](makefile.md)
## [related](related.md)


