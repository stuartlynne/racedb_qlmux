#!/bin/bash


_inspect() {
    RUNNING="$(docker inspect -f '{{.State.Running}}' $1)"
    stderr RUNNING: $RUNNING
    if [ -n "${RUNNING}" -a "${RUNNING}" = "true" ] ; then stderr inspect_OK; return 0 ;
    else
    stderr inspect_NOT ;  return 1; fi
}

inspect() {
    _inspect $1 2>/dev/null > /dev/null
    #RC=$?
    #echo RC: $RC
    return $?
}

inspect $1
if [ $? -eq 0   ]; then 
    exit 0;
else 
    exit 1; 
fi




