#!/bin/bash

LOGFILE="/var/log/varnish/ttl_expired.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
EXPIRED=$(varnishstat -1 -f MAIN.n_expired 2>/dev/null | awk '{print $2}')

if [ -n "$EXPIRED" ]; then
    echo "$TIMESTAMP $EXPIRED" >> "$LOGFILE"
fi
