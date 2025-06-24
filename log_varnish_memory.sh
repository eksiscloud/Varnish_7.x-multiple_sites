#!/bin/bash

# 0 * * * * /usr/local/bin/log-varnish-memory.sh

# Where is...
LOGFILE="/var/log/varnish-memory.csv"

# Datw and time
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Find out which  SMA-pool is in use (i.e. SMA.s0)
sma_pool=$(varnishstat -1 | awk '/^SMA\.[^.]+\.g_bytes/ {print $1}' | cut -d'.' -f1-2 | head -n 1)

# Abort if no pool
if [[ -z "$sma_pool" ]]; then
    echo "$timestamp,ERROR: No SMA pool found" >> "$LOGFILE"
    exit 1
fi

# Get values
g_bytes=$(varnishstat -1 -f "$sma_pool.g_bytes" | awk '{print $2}')
g_space=$(varnishstat -1 -f "$sma_pool.g_space" | awk '{print $2}')
n_object=$(varnishstat -1 -f MAIN.n_object 2>/dev/null | awk '{print $2}')

# If values are missing, do not count
if [[ -z "$g_bytes" || -z "$g_space" ]]; then
    echo "$timestamp,ERROR: Missing memory values" >> "$LOGFILE"
    exit 1
fi

# Count utilisation rate
total_bytes=$(echo "$g_bytes + $g_space" | bc)
usage_percent=$(echo "scale=1; 100 * $g_bytes / $total_bytes" | bc)

# Count average size of objects (if possible)
if [[ -n "$n_object" && "$n_object" -gt 0 ]]; then
    avg_object_size=$(echo "$g_bytes / $n_object" | bc)
else
    avg_object_size=0
    n_object=0
fi

# Add CSV-line
echo "$timestamp,$g_bytes,$g_space,$total_bytes,$usage_percent,$n_object,$avg_object_size" >> "$LOGFILE"
