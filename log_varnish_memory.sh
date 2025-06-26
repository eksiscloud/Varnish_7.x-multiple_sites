#!/bin/bash

# Where to log
LOGFILE="/var/log/varnish-memory.csv"

# Date and time
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Find out which  SMA-pool is in use (i.e. SMA.s0)
sma_pool=$(varnishstat -1 | awk '/^SMA\.[^.]+\.g_bytes/ {print $1}' | cut -d'.' -f1-2 | head -n 1)

if [[ -z "$sma_pool" ]]; then
    echo "$timestamp,ERROR: No SMA pool found" >> "$LOGFILE"
    exit 1
fi

# Getting memoryvalues
g_bytes=$(varnishstat -1 -f "$sma_pool.g_bytes" | awk '{print $2}')
g_space=$(varnishstat -1 -f "$sma_pool.g_space" | awk '{print $2}')
c_bytes=$(varnishstat -1 -f "$sma_pool.c_bytes" | awk '{print $2}')
c_freed=$(varnishstat -1 -f "$sma_pool.c_freed" | awk '{print $2}')

# Amount of objects and expired
n_object=$(varnishstat -1 -f MAIN.n_object 2>/dev/null | awk '{print $2}')
n_expired=$(varnishstat -1 -f MAIN.n_expired 2>/dev/null | awk '{print $2}')

# If missing obligatory values
if [[ -z "$g_bytes" || -z "$g_space" ]]; then
    echo "$timestamp,ERROR: Missing memory values" >> "$LOGFILE"
    exit 1
fi

# Counting totally and usage percent
total_bytes=$(echo "$g_bytes + $g_space" | bc)
usage_percent=$(echo "scale=1; 100 * $g_bytes / $total_bytes" | bc)

# Average object size
if [[ -n "$n_object" && "$n_object" -gt 0 ]]; then
    avg_object_size=$(echo "$g_bytes / $n_object" | bc)
else
    avg_object_size=0
    n_object=0
fi

# If there isn't value for expired
if [[ -z "$n_expired" ]]; then
    n_expired=0
fi

# CSV-header (writing only if not exist)
if [[ ! -f "$LOGFILE" ]]; then
    echo "timestamp,g_bytes,g_space,total_bytes,usage_percent,n_object,avg_object_size,c_bytes,c_freed,n_expired" > "$LOGFILE"
fi

# CSV-line
echo "$timestamp,$g_bytes,$g_space,$total_bytes,$usage_percent,$n_object,$avg_object_size,$c_bytes,$c_freed,$n_expired" >> "$LOGFILE"
