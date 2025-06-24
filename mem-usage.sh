#!/bin/bash

# Haetaan mallocin käytössä oleva ja vapaa muisti
used_bytes=$(varnishstat -1 -f SMA.s0.g_bytes | awk '{print $2}')
free_bytes=$(varnishstat -1 -f SMA.s0.g_space | awk '{print $2}')

# Lasketaan kokonaismäärä
total_bytes=$(echo "$used_bytes + $free_bytes" | bc)

# Lasketaan käyttöaste prosentteina
usage_percent=$(echo "scale=1; 100 * $used_bytes / $total_bytes" | bc)

# Muunnetaan GiB-yksiköihin
used_gb=$(echo "scale=2; $used_bytes / 1024 / 1024 / 1024" | bc)
free_gb=$(echo "scale=2; $free_bytes / 1024 / 1024 / 1024" | bc)
total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)

# Tulostus
echo
echo "Varnish malloc memory usage:"
echo "----------------------------"
printf "  Used memory:       %.2f GiB (%.1f %% of pool)\n" "$used_gb" "$usage_percent"
printf "  Free memory:       %.2f GiB\n" "$free_gb"
printf "  Total pool size:   %.2f GiB\n" "$total_gb"
echo

# Suositus (heuristinen)
if (( $(echo "$usage_percent < 20" | bc -l) )); then
    echo "💡 Käyttöaste on alhainen. Voit todennäköisesti pienentää malloc-poolin kokoa."
else
    echo "✅ Käyttöaste vaikuttaa perustellulta nykyiseen kokoon nähden."
fi

echo
