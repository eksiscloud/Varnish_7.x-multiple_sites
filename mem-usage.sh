#!/bin/bash

# Hae ajantasaiset muistiarvot
current_bytes=$(varnishstat -1 -f SMA.s0.g_bytes | awk '{print $2}')
available_bytes=$(varnishstat -1 -f SMA.s0.g_space | awk '{print $2}')

# Lasketaan kokonaisvarattu muistialue (käytetty + vapaa)
total_bytes=$(echo "$current_bytes + $available_bytes" | bc)

# Muunnetaan GiB-yksikköihin
current_gb=$(echo "scale=2; $current_bytes / 1024 / 1024 / 1024" | bc)
available_gb=$(echo "scale=2; $available_bytes / 1024 / 1024 / 1024" | bc)
total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)

# Lasketaan käyttöaste prosentteina
usage_percent=$(echo "scale=1; 100 * $current_bytes / $total_bytes" | bc)

# Haetaan objektien määrä (jos saatavilla)
object_count=$(varnishstat -1 -f SMA.s0.g_alloc 2>/dev/null | awk '{print $2}')

# Tulostetaan yhteenveto
echo
echo "Varnish Cache - memory usage (malloc backend):"
echo "-----------------------------------------------"
echo "Memory in use:             ${current_gb} GiB (${usage_percent} % of pool)"
echo "Memory still available:    ${available_gb} GiB"
echo "Total malloc pool size:    ${total_gb} GiB"

if [[ -n "$object_count" ]]; then
    echo "Currently cached objects:  $object_count"
else
    echo "Object count is not available."
fi
