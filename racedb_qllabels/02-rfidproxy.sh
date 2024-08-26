#!/bin/bash

function stderr() {
    echo 1>&2 "${*}"
}

# N.B. DATABASE_TYPE is inherited from esitarksi/racedb and normally will default to psql-local
# We do not support any other configuration.

stderr 
stderr "-----------------------------------------------"
stderr "02-rfidproxy.sh"
stderr "-----------------------------------------------"

stderr "Start simply http server"
( rfidproxy ) &
stderr "***************************************************************"
set -x

