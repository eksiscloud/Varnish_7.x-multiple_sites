#!/bin/bash
#
# Varnish-muistin pudotuksen debug-skripti
# Tallentaa järjestelmän tilanteen, jos Varnishin muistikulutus romahtaa
#
# Suositeltu ajastus esim. 5 minuutin välein crontabissa

LOGDIR="/var/log/varnish_memory_watch"
mkdir -p "$LOGDIR"
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$LOGDIR/varnish_debug_$NOW.log"

echo "=== Varnish Memory Debug ===" > "$LOGFILE"
echo "Timestamp: $NOW" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Varnish PID ja muistitiedot
VARNISHPID=$(pidof varnishd)
echo ">> /proc/$VARNISHPID/status:" >> "$LOGFILE"
grep -E 'VmRSS|VmSize|VmData' /proc/$VARNISHPID/status >> "$LOGFILE"
echo "" >> "$LOGFILE"

# varnishstat snapshot
echo ">> varnishstat (selected fields):" >> "$LOGFILE"
varnishstat -1 -f SMA.s0.c_bytes,SMA.s0.g_bytes,SMA.s0.c_objects,SMA.s0.g_space,MAIN.n_expired,MAIN.n_lru_nuked >> "$LOGFILE" 2>/dev/null
echo "" >> "$LOGFILE"

# Kernel logista mahdollisia muistiviitteitä
echo ">> Kernel/syslog memory-related messages (past 5 minutes):" >> "$LOGFILE"
journalctl --since "5 min ago" | grep -Ei 'oom|kill|memory|swap|invoked' >> "$LOGFILE"
echo "" >> "$LOGFILE"

# dmesg mahdolliset viimeisimmät viestit
echo ">> dmesg -T | tail -n 20:" >> "$LOGFILE"
dmesg -T | tail -n 20 >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- Done ---" >> "$LOGFILE"
