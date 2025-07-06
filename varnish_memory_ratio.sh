#!/bin/bash

# Shows the ratio of cache and true RAM usage

# Find varnishd PID
PID=$(pidof varnishd | awk '{print $1}')
if [[ -z "$PID" ]]; then
    echo "❌ Varnish isn't in use?"
    exit 1
fi

# Get SMA.s0.g_bytes from varnishstat
BYTES=$(varnishstat -1 | awk '/SMA.s0.g_bytes/ {print $2}')
if [[ -z "$BYTES" ]]; then
    echo "❌ SMA.s0.g_bytes didn't find. Is malloc in use?"
    exit 1
fi

# Read RSS-value from /proc 
RSS_KB=$(grep VmRSS /proc/$PID/status | awk '{print $2}')
if [[ -z "$RSS_KB" ]]; then
    echo "❌ Couldn't read VmRSS-value."
    exit 1
fi

RSS_BYTES=$((RSS_KB * 1024))

# Counting ratio
RATIO=$(awk "BEGIN {printf \"%.2f\", $RSS_BYTES / $BYTES}")

# Show results
echo "🧠 Cache (SMA.s0.g_bytes): $BYTES bytes ($(numfmt --to=iec $BYTES))"
echo "📦 RSS (true RAM-usage): $RSS_BYTES bytes ($(numfmt --to=iec $RSS_BYTES))"
echo "📊 Ratio (RAM / cache): $RATIO ×"

# Should be 1x – 3x depending differences between object size etc. 
