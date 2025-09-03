#!/usr/bin/env bash
set -euo pipefail

# single-run lock
exec 9>/run/varnish_switchover.lock
flock -n 9 || exit 0

EMER_FLAG="/run/emergency_on"
OK_CNT="/run/varnish_ok.count"
BAD_CNT="/run/varnish_bad.count"
BP_FLAG="/run/bypass_varnish_on"

# Hysteresis-helpers
inc()   { local f="$1"; local n=0; [[ -f "$f" ]] && n=$(cat "$f" 2>/dev/null || echo 0); echo $((n+1)) > "$f"; }
reset() { : > "$1"; }

# Checking if normal Varnish is healthy
healthy=0
if varnishadm -T 127.0.0.1:6082 -S /etc/varnish/secret -t 1 ping >/dev/null 2>&1; then
  healthy=1
fi

if (( healthy )); then
  inc "$OK_CNT"; reset "$BAD_CNT"
  # needs 2 OK before returning
  if (( $(cat "$OK_CNT") >= 2 )); then
    [[ -f "$EMER_FLAG" ]] && rm -f "$EMER_FLAG"
    [[ -f "$BP_FLAG"   ]] && rm -f "$BP_FLAG"
  fi
else
  inc "$BAD_CNT"; reset "$OK_CNT"
  # needs 1 BAD to raise the flag
  if (( $(cat "$BAD_CNT") >= 1 )); then
    [[ -f "$EMER_FLAG" ]] || touch "$EMER_FLAG"
    # if panic-Varnish is dead too → Apache-bypass
    if ! varnishadm -T 127.0.0.1:6083 -S /etc/varnish/secret -t 1 ping >/dev/null 2>&1; then
      [[ -f "$BP_FLAG" ]] || touch "$BP_FLAG"
    else
      [[ -f "$BP_FLAG" ]] && rm -f "$BP_FLAG"
    fi
  fi
fi
