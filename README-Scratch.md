# Linux From Scratch Install Notes

## Overview
These are notes from my install to support *racedb_qlmux* on a laptop for use at events.

This supports:
    - a single RFID reader with up to four RFID wands
    - two to four QL710w or QL720nw label printers allocated to left or right side
    - one or two QL1060n label printers allocated to left or right side

All devices other than the laptop are DHCP enabled and connect to the racedb WiFi network or via Ethernet.

SNMP is used for discovery of the printers and RFID reader.

Internet access is via and Android phone with USB HotSpot. Internet access is not provided for Chromebooks or other devices.

wireguard is used to allow remote access to the server via VPN. This is used to download the CrossMgr files and allow 
access to RaceDB from the finish line. 


Hardware:

    - i5 laptop with Ethernet port, WiFi and USB, DNS enabled on Ethernet
    - WiFi router setup for racedb SSID
    - QL710w, QL720nw setup configured for SSID racedb, DHCP IP
    - QL1060n label printers, connected to Ethernet, DHCP IP
    - Impinj R1000 (or R420) RFID reader, connected to Ethernet, DHCP IP
    - Android Phone, with USB tethering enabled as default (developer mode)
    - Chromebook, connect with WiFi to racedb SSID, DHCP IP, DNS set to racedb IP, secure DNS disabled
   

## WiFi Router
- SSID: racedb
- Network: 192.168.40/24
- DHCP - 192.168.40.100-192.168.40.200

## Laptop Overview
- Install Linux Mint 22
- Install Debian packages
- Install Python packages
- Power settings
- Setup Networking
- Setup DNS for Chromebooks

N.b. Generally I use older laptops for this purpose, as they are less expensive (eBay), more robust and have more ports.
Replacing a rain-damaged laptop for a few hundred dollars is less painful than a new laptop. And for this purpose
is more than adequate. 

### Linux
- Linux Mint 22
- auto login
- disable all power management settings, never sleep, never screen saver, power button disabled, 
- disable all screen lock settings, do not turn screen off, do not lock screen  

### Debian Packages

- git
- docker.io
- docker-compose-v2
- openssh-server
- vim
- wireguard

### Python packages

### Networking

- WiFi or USB0 is used for internet access.
- Ethernet is used for local devices. 
- wireguard is used to allow remote access to the server via VPN.

N.b. clients on the Ethernet do not have Internet access.

| Device | IP | Gateway |
| --- | --- | --- |
| Wi-Fi | DHCP | from DHCP server |
| USB0 | DHCP | from DHCP server |
| Ethernet | 192.168.40.51/24 | no gateway |
| Wireguard | 192.168.250.51/24 | no gateway |

N.b. ensure that the local Ethernet (used for access to printers and rfid reader) DO NOT have a gateway set. 

N.b. only one of WiFi or USB0 should be used at a time, not both. Just use default DHCP settings, possibly with static DNS (e.g. 1.1.1.1, 8.8.8.8).


### Settings
- power settings - never sleep for anything
- screensaver settings - never lock screen
- network settings - static IP

### DNS
- /etc/hosts
    192.168.40.51 racedb
    192.168.40.51 racedb.wimsey.online
    192.168.40.51 qlmuxproxy.wimsey.online
    192.168.250.51 racedb.wg

- /etc/systemd/resolved.conf
    - DNSStubListenerExtra=192.168.40.16

## QL Printers
- WiFi SSID: racedb (ql710w, ql720nw)
- Network: DHCP
- hostname: append '-left', or '-right' to the hostname to change default printer queue

## Impinj RFID Readers
- Network: DHCP
- append '-table' or '-kiosk' to the hostname to change target ip address
    - '-table' - 127.0.0.1
    - '-kiosk' - 127.0.0.2

## Chromebooks
- WiFi SSID: racedb
- Network: DHCP
- DNS: 192.168.40.51
- ChromeSecure DNS: off
    - Go to chrome://settings
    - Click on "Privacy and Security" on the top right.Inside the center menu, click "Security".Go to chrome://settings
    - find "Use secure connections to look up sites" and turn it off.
- Disable password checks
    - Go to chrome://settings
    - privacy and security / sync services / disable password checks

N.b. Chromebooks are used for registration and results. They do not have internet access. Set up in this
fashion will be insecure for normal use.

## racedb\_qlmux install

### Clone
```
git clone https://github.com/stuartlynne/racedb_qlmux.git
```

## Project outline

```
/racedb_qlmux
  |-- racedb_scripts
  |-- qlmux_proxy
  |-- traefik_racedb
  |-- racedb_qllabels
  |-- racedb_qllabels/racedb-data
  |-- racedb_ssh
  |-- racedb_ssh/racedb-data
```

## qlmux\_proxy

- build and start container
```
cd qlmux_proxy
make up logs
```

## traefik

- edit docker.env, set your email, dns provider, domain, hostnames, etc.
- sample
```
# Email
export TRAEFIK_EMAIL=stuart.lynne@gmail.com
export TRAEFIK_DNS_PROVIDER=namecheap
export WILDCARD_DOMAIN=*.wimsey.online

# Router and port hostnames and ports
export RACEDB_HOSTNAME="racedb.wimsey.online"
export RACEDB_PORT=9080
export QLMUXPROXY_HOSTNAME="qlmuxproxy.wimsey.online"
export QLMUXPROXY_PORT=9180


# Traefik configuration
export TRAEFIK_LOG_LEVEL=DEBUG
export TRAEFIK_DNS_DELAY_BEFORE_CHECK=60
```

- setup dnschallange.env, you will need your DNS provider username and api key.
```
cd traefik
cp dnschallange.env-template dnschallenge.env
vi dnschallange.env
```

- sample, this is for namecheap, other providers may be different:
```
# Namecheap configuration
NAMECHEAP_API_USER=YOUR_NAMECHEAP_USERNAME
NAMECHEAP_API_KEY=f1282039d149419ba1ae8a38d79e3180
```
- build and start container
```
cd traefik
make up logs
```


## racedb\_ssh
- edit docker.env, add fully qualified hostname to CSRF\_TRUSTED\_ORIGINS
```
cd racedb_ssh
vi docker.env
```
- sample
```
# This will be added to the /RaceDB/RaceDB/settings.py file.
# It is used to set the CSRF_TRUSTED_ORIGINS variable in the Django settings file.
# This is required if using a proxy to allow https access.
# The value is a comma separated list of trusted origins and will be added to the settings file as:
#  CSRF_TRUSTED_ORIGINS = ['https://racedb.wimsey.dev', 'https://racedb.wimsey.pro'] by the csrf.py script.
#export DOCKERBUILDARGS=--build-arg "CSRF_TRUSTED_ORIGINS=https://racedb.wimsey.dev,https://racedb.wimsey.pro,https://racedb.wimsey.online"
export DOCKERBUILDARGS=--build-arg "CSRF_TRUSTED_ORIGINS=https://racedb.wimsey.online"
```
- build and start container
```
cd traefik
make up logs
```

## Web Pages
Verify that the following are available in Firefox or Chrome:
- on the racedb linux host (e.g. console)
- on registration clients (e.g. Chromebooks)
### Racedb
- http://192.168.40.51:9080/RaceDB
- https://racedb.wimsey.online/RaceDB

### QLMuxProxy
- http://192.168.40.51:9180/
- https://qlmuxproxy.wimsey.online/

