# Linux Laptop Prep
## Overview

- Install Linux Mint
- Configure basic
- Install other programs


### Install Linux Mint

As of 2024-02-28 older laptops, e.g. HP Elitebook e8460, do not work correctly with current Linux Mint 22. 
Installation works, but it cannot boot because Grub does not properly install compatibly with the older BIOS.

Work around is to fall back to Mint 21.

### Configure Basic

- terminal 
    - black on white
    - 110x40

- power management
    - never shutdown when plugged in
    - shutdown after 30 minutes if on battery
    - ask if shutdown button is pressed

- screensaver
    - delay 30 minutes
    - lock computer when put to sleep OFF
    - lock computer after screensaver starts OFF

### Other Programs

Apt:
- git-all
- docker
- docker.io
- docker-compose
- openssh-server

### Portainer-CE
Portainer-CE is a web based tool for monitoring, starting and stopping containers.

```
#!/bin/bash
set -x

```

### SSH

scp name@host:ssh.tgz .

### 10.0.0

- route  to verify that 10.0.0 is not in use by another interface or bridge
- brctl show to see bridge info
- docker network ls to see if docker network is using bridge
- docker network rm to remove



