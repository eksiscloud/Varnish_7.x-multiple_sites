#!/bin/bash

# Get what  malloc uses and free memory
used_bytes=$(varnishstat -1 -f SMA.s0.g_bytes | awk '{print $2}')
free_bytes=$(varnishstat -1 -f SMA.s0.g_space | awk '{print $2}')

# Counting total
total_bytes=$(echo "$used_bytes + $free_bytes" | bc)

# Counting usage
usage_percent=$(echo "scale=1; 100 * $used_bytes / $total_bytes" | bc)

# Change to GiB
used_gb=$(echo "scale=2; $used_bytes / 1024 / 1024 / 1024" | bc)
free_gb=$(echo "scale=2; $free_bytes / 1024 / 1024 / 1024" | bc)
total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)

# Results
echo
echo "Varnish malloc memory usage:"
echo "----------------------------"
printf "  Used memory:       %.2f GiB (%.1f %% of pool)\n" "$used_gb" "$usage_percent"
printf "  Free memory:       %.2f GiB\n" "$free_gb"
printf "  Total pool size:   %.2f GiB\n" "$total_gb"
echo

# What to change (heuristic)
# This is... not so reliable way ;)
if (( $(echo "$usage_percent < 20" | bc -l) )); then
    echo "💡 Usage is low. You could propably reduce the size of malloc-pool."
else
    echo "✅ Usage seems to be good, when compared to the size."
fi

echo
