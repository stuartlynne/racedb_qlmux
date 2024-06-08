# qlmux_proxy container

## Description

This is a container that runs the qlmux_proxy application. It handles printing of labels for *RaceDB*
on Brother QL printers and implements a proxy to handle the communication between *RaceDB* and 
an Impinj RFID reader.

## Dockerfile

This creates an image based on python:3.10.0-alpine and installs the necessary dependencies.

## docker-compose.yml

This creates a container based on the image created by the Dockerfile.

N.b. The container needs to be run with the *network_mode: host* option to allow it to use
SNMP Broadcasts to find printers and RFID readers.


## Usage

Once the container is running, the qlmux_proxy application will be available on ports:

- 9101-9104 to receive print data from *RaceDB* 
- 5084 RFID data to proxy to the Impinj reader 
- 9180 is a web interface to view the status of printers and rfid readers


## Configuration in RaceDB

*RaceDB* needs to be configured to send print data to the qlmux_proxy application. This is done by
configuring the LP print command in Systeminfo->Printer Configuration. 

There are two options depending on how the RaceDB container is configured:

- using qllabels.py $1 if it is available in the RaceDB container
- ssh to excute qllabels.py on the qlmux_proxy container racedb@qlmux_proxy.local qllabels.py $1

The first option is the simplest and most efficient, but requires the qllabels.py script to be available in the RaceDB container.

The second option is slightly more complex, and requires that openssh is installed in the RaceDB container.


## qllabels

The qllabels.py script takes the label PDF filename as an argument and the data on <STDIN>. 

The PDF is converted to an image, and the image is converted into the Brother QL Raster format.

The raster data is then sent to the printer via the network using one of 9101, 9102, 9103 or 9104 ports.

- 9101 - small labels from stations 1-2
- 9102 - small labels from stations 3-4
- 9103 - large labels from stations 1-2
- 9104 - large labels from stations 3-4

The station information and size is determined from the label PDF filename.

