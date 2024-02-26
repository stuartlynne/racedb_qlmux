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

### Portainer
Portainer is a web based tool for monitoring, starting and stopping containers.

```
#!/bin/bash
set -x
docker run -d -p 9000:9000 --name=portainer --restart=unless-stopped -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

```

### SSH

scp name@host:ssh.tgz .


