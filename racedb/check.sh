#!/bin/bash
set -x

#F=$(echo 'SELECT TRIM(LEADING FROM pg_is_in_recovery());' | psql -U postgres --tuples-only )

F=$(echo 'SELECT pg_is_in_recovery();' | psql -U postgres --tuples-only ) || exit 1


case $F in
	*f*) 
        echo running; 
        exit 0;
        ;;
	*t*) 
        echo standby; 
        exit 1;
            ;;
	*) 
        echo F: \"$F\" 
        exit 1;
        ;;
esac
