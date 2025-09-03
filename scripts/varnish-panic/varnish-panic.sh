#!/usr/bin/env bash

# Automatic panic handling

set -euo pipefail
exec 9>/run/varnish-panic.lock
flock -n 9 || { echo "panic varnish already running"; exit 0; }

# Original:
# varnishd -I /etc/varnish/start.cli.emerg -P /var/run/varnish.pid \
#  -j unix,user=vcache -F -a :8080 -T localhost:6082 -f "" \
#  -S /etc/varnish/secret -s malloc,256M

/usr/sbin/varnishd \
  -n panic \
  -a 127.0.0.1:8081 \
  -T 127.0.0.1:6083 \
  -S /etc/varnish/secret \
  -s malloc,256M \
  -j unix,user=vcache \
  -F \
  -f '' \
  -I /etc/varnish/start.cli.emerg
