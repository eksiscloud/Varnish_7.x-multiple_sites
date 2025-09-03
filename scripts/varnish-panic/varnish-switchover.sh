#!/usr/bin/env bash
set -euo pipefail

# stop doing several ones at the same time
exec 9>/run/varnish_switchover.lock
flock -n 9 || exit 0

HEALTH_URL="http://127.0.0.1:8080/"
EMER_FLAG="/run/emergency_on"
OK_CNT="/run/varnish_ok.count"
BAD_CNT="/run/varnish_bad.count"
BAD_SINCE="/run/varnish_bad_since.ts"
MIN_BAD_SEC=10

# Checking if actual Varnish is healthy
if varnishadm -T 127.0.0.1:6082 -S /etc/varnish/secret -t 1 ping >/dev/null 2>&1; then
  healthy=1
else
  healthy=0
fi

inc()   { local f="$1"; local n=0; [[ -f "$f" ]] && n=$(cat "$f" 2>/dev/null || echo 0); echo $((n+1)) > "$f"; }
reset() { : > "$1"; }

if (( healthy )); then
  # reseting “bad since”
  [[ -f "$BAD_SINCE" ]] && rm -f "$BAD_SINCE"
  # keep small hysteresis: 2 OK in the row before dropping the flag
  inc "$OK_CNT"; reset "$BAD_CNT"
  if (( $(cat "$OK_CNT") >= 2 )); then
    [[ -f "$EMER_FLAG" ]] && rm -f "$EMER_FLAG"
  fi
else
  # first BAD → mark startingtime (at this point Plesk get time to do its jobs, like post to Discourse)
  if [[ ! -f "$BAD_SINCE" ]]; then
    date +%s > "$BAD_SINCE"
    reset "$OK_CNT"
  fi
  inc "$BAD_CNT"
  bad_for=$(( $(date +%s) - $(cat "$BAD_SINCE" 2>/dev/null || echo 0) ))
  # raise the flag when BAD has been at least MIN_BAD_SEC
  if (( bad_for >= MIN_BAD_SEC )); then
    [[ -f "$EMER_FLAG" ]] || touch "$EMER_FLAG"
  fi
fi
