#!/bin/bash

# Collecting data
used_bytes=$(varnishstat -1 -f SMA.s0.c_bytes | awk '{print $2}')
garbage_bytes=$(varnishstat -1 -f SMA.s0.g_bytes | awk '{print $2}')
object_count=$(varnishstat -1 -f SMA.s0.c_objects 2>/dev/null | awk '{print $2}')

# Total usage
total_bytes=$(echo "$used_bytes + $garbage_bytes" | bc)

# Human readable GB
used_gb=$(echo "scale=2; $used_bytes / 1024 / 1024 / 1024" | bc)
garbage_gb=$(echo "scale=2; $garbage_bytes / 1024 / 1024 / 1024" | bc)
total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)

# Counting garbage share
garbage_percent=$(echo "scale=1; 100 * $garbage_bytes / $total_bytes" | bc)

# Printing
echo
echo "Varnish Cache - memory usage:"
echo "-----------------------------------------------"
echo "Memory in use:             ${used_gb} GiB"
echo "Marked as garbage:         ${garbage_gb} GiB (${garbage_percent}% of memory)"
echo "Totally in use:            ${total_gb} GiB"

#if [[ -n "$object_count" ]]; then
#    echo "Amount of objects in cache: $object_count"
#else
#    echo "Amount of objects isn't available (not supporter or no data)."
#fi
