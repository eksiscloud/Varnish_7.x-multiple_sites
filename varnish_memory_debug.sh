#!/bin/bash
#
# Amount of RAM went to zero every now and then.
# This logs some metrics.
#
# Use crontab, i.e. every 5 minutes.
#
# the guilty one of was one unactive cache purging plugin in one WordPress.
# When using wget to build up snapshot-backend, it sended BAN for everything.

LOGDIR="/var/log/varnish_memory_watch"
mkdir -p "$LOGDIR"
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$LOGDIR/varnish_debug_$NOW.log"

echo "=== Varnish Memory Debug ===" > "$LOGFILE"
echo "Timestamp: $NOW" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Varnish PID and memory
VARNISHPID=$(pidof varnishd)
echo ">> /proc/$VARNISHPID/status:" >> "$LOGFILE"
grep -E 'VmRSS|VmSize|VmData' /proc/$VARNISHPID/status >> "$LOGFILE"
echo "" >> "$LOGFILE"

# varnishstat snapshot
echo ">> varnishstat (selected fields):" >> "$LOGFILE"
varnishstat -1 -f SMA.s0.c_bytes,SMA.s0.g_bytes,SMA.s0.c_objects,SMA.s0.g_space,MAIN.n_expired,MAIN.n_lru_nuked >> "$LOGFILE" 2>/dev/null
echo "" >> "$LOGFILE"

# Kernel log
echo ">> Kernel/syslog memory-related messages (past 5 minutes):" >> "$LOGFILE"
journalctl --since "5 min ago" | grep -Ei 'oom|kill|memory|swap|invoked' >> "$LOGFILE"
echo "" >> "$LOGFILE"

# dmesg last messages
echo ">> dmesg -T | tail -n 20:" >> "$LOGFILE"
dmesg -T | tail -n 20 >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- Done ---" >> "$LOGFILE"
