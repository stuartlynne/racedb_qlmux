
# RaceDB QLMux

## Overview

The RaceDB QLMux project is designed to provide a robust and easily deployable system for running RaceDB with integrated support for Brother QL printers and Impinj RFID readers. This system is ideal for events where efficient management of registration and timing is critical.

### Key Goals:
- **On-Demand Printing**: Support for on-demand printing of BIB and frame numbers using Brother QL printers.
- **Simple Configuration**: Easy configuration for RaceDB to support Brother QL printers and Impinj RFID readers.
- **Automatic Device Discovery**: Use SNMP to discover and manage multiple Brother QL printers and Impinj RFID readers on the network.
- **Secure Access**: Provide a reverse proxy for secure *https* access to the RaceDB web interface and QLMux Proxy web status page.

Wimsey and Escape Velocity have been using Impinj RFID readers and Brother QL label printers to support timing and registration since 2014/2015. The use of low-cost RFID tags allowed racers to retain their tags for future events, enabling RaceDB to quickly recognize returning participants.

On-demand printing of BIB and frame numbers has significantly reduced the time required for rider registration and check-in at events. These improvements have also decreased the number of volunteers needed. Typically, two or three volunteers can manage the registration and check-in for a 100-200 rider event in less than an hour. With four volunteers, 200-300 riders can be processed in the same time frame. This efficiency assumes approximately 50% pre-registration and 50% day-of registration, with a similar percentage of riders having their own RFID tags.

## Background

The [racedb_qlmux](https://github.com/stuartlynne/racedb_qlmux) project is a revised version of the older *racedb_qlmuxd* archive. It includes management scripts to support running RaceDB, PostgreSQL, QLMux Proxy, and Traefik in containers on a Linux system.

This updated version uses the new *QLMux Proxy*, an enhanced version of qlmuxd, which leverages *SNMP* to find and monitor the status of Brother QL printers and Impinj RFID readers.

If you want to integrate *QLMux Proxy* and *Traefik* into an existing *RaceDB* installation, you can use the provided tools and documentation.

## Related Projects

- **[traefik_racedb](https://github.com/stuartlynne/traefik_racedb)**: Support for QLMux Proxy and Traefik containers to integrate with an existing RaceDB installation.
- **[racedb_qlmux](https://github.com/stuartlynne/racedb_qlmux)**: A complete set of containers for implementing PostgreSQL, RaceDB, QLMux Proxy, and Traefik.

## Installation

Detailed instructions for installation and configuration are provided in the Makefile. For containerized deployment, refer to the `docker/docker.md` file for a simple build and run example.

### Note

When running the QLMux Proxy container, make sure to use host networking (`--network=host`) to allow SNMP broadcast discovery to function correctly.
