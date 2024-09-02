# qlmux_proxy container

## Description

This is a container that runs the qlmux_proxy application. It handles printing of labels for *RaceDB*
on Brother QL printers and implements a proxy to handle the communication between *RaceDB* and 
an Impinj RFID reader.

Printers and Readers are discovered using SNMP broadcasts, and the container will automatically detect and configure them.

The container also provides a web interface to view the status of the printers and RFID readers and determine
which printers and readers are used.

### Printer Queues
qlmux_proxy uses two queues to handle spooling of labels to the printers:

    - left - intended for printers used by stations on the left end of the table
    - right - intended for printers used by stations on the right end of the table
    - center - backup for all stations


By default the label will be printed on the:
- left (or right) printer that is available and has been idle the longest.
- If no printer is available, the label will be printed on the center printer. 
- If there is no center printer available, the label will printed on the other right (or left) printer that is available.
- If no printer available it will be queued until a printer becomes available.


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

## Printer Configuration

- DHCP - The printer should be configured to use DHCP to get an IP address
- Hostname - The printer should have a hostname set to the name of the printer
- Queue - if the hostname ends in "-left" or "-right" the printer will be used for the left or right queue
otherwise it will be used for the center queue

The queue can be changed in the web interface.

## RFID Reader Configuration
- DHCP -The reader should be configured to use DHCP to get an IP address.
- Hostname - The reader should have a hostname set to the name of the reader
- Usage - If the hostname ends in "-table" the reader will be used for the table, if "-kiosk" it will be used for the kiosk

The usage can be changed in the web interface.

### Table vs Kiosk
- Table - RaceDB should be configured to use 127.0.0.1
- Kiosk - RaceDB should be configured to use 127.0.0.2












