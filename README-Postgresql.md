# Postgresql Notes

The RaceDB container set uses Postgresql as it's database server.

The containers are set up to be deployed to two different systems at an event
(typically two identical laptops.) One acts as the *primary* RaceDB server
and the other acts as the *standby* server.

The *primary* server contains the current active database for RaceDB.

The *standby* server maintains a connection to the *primary* server and keeps an
uptodate copy of the RaceDB database. 

If the primary server fails (i.e. a hardware problem etc.) then standby server can be quickly
changed to *failover* mode and all RaceDB operations can continue using that system. Typically
this takes only a few minutes (access the standby system to change to failover, change each
registration station to the standby server IP address.)

## Roles

Postgresql operates in several different modes:

1. Standby
    - replicating - copy complete database from primary, then track changes
    - failover - act as primary using database from standby
2. Primary
    - default - primary server using existing database
    - recovery - restore existing database, then change to primary

## $PGDATA/standby.signal

If this file exists then *postgresql* will start as a standby server replicating from a *primary server*.

- before starting *postgresql* the *entrypoint.sh* script must do a *pg\_basebackup* restore from
the *primary server* it is acting as standby for
- once started *postgresql* will connect to the *primary server* to get WAL records to maintain
a current backup
- *postgresql* will watch for the existance of the *postgresql.conf[promote\_trigger\_file]*.


## $PGDATA/standby.signal and trigger\_file (as defined in postgresql.conf)

If this file is created while *postgresql* is running in standby mode it will
immediately convert to acting as a primary server.


## $PGDATA/recovery.signal

If this file *DOES NOT EXIST* then *postgresql* will work as the primary server.

If this file *DOES EXIST* then *postgresql* will start in recovery mode:

- *postgresql* will use postgresql.conf[restore\_command] to restore database
- *postgresql* will *remove* the *$PGDATA/recovery.signal* file
- *postgresql* will work as the primary server.

N.B. if both $PGDATA/recovery.signal and $PGDATA/standby.signal exist, standby takes priority.

## RaceDB

RaceDB will only start if neither of the signal files exists and if *postgresql* is running.


## PRIMARY Fails, STANDBY goes to FAILOVER

| PRIMARY                   | STANDBY               | RaceDB Server         |
| -----------------         | ------------------    | -----------------     |
| Normal startup            | Wait for PRIMARY      | Using Primary         |
| Running                   | Replicate PRIMARY     |                       |
|                           | Receive WAL records   |                       |
| Failure                   |                       |                       |
|                           | Trigger file created  |                       |
|                           | Operate in FAILOVER   | Switch to Secondary   |




## PRIMARY Restored from STANDBY

| PRIMARY                   | STANDBY               |
| -----------------         | ------------------    |
|                           | Operating in FAILOVER |
| restore-standby created   |                       |
| Startup                   |                       |
| Replicate from STANDBY    |                       |
| Normal operation          |                       | 



