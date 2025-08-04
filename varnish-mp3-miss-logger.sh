#!/bin/bash

# Uses varnish-mp3-miss.service (disabled)

# Create the log if needed
mkdir -p /var/log/varnish
LOGFILE="/var/log/varnish/mp3_miss.log"
touch "$LOGFILE"
chown varnish:adm "$LOGFILE"

# Start  varnishncsa and filter MP3 MISS-lines
exec /usr/bin/varnishncsa -n varnishd | \
    awk '/\.mp3/ && /MISS/ { print strftime("[%Y-%m-%d %H:%M:%S] "), $0 >> "'"$LOGFILE"'" ; fflush() }'
