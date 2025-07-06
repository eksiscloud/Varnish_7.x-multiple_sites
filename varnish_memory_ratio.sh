#!/bin/bash

# Etsi varnishd:n PID
PID=$(pidof varnishd | awk '{print $1}')
if [[ -z "$PID" ]]; then
    echo "❌ Varnish ei näytä olevan käynnissä."
    exit 1
fi

# Hae SMA.s0.g_bytes varnishstatilla
BYTES=$(varnishstat -1 | awk '/SMA.s0.g_bytes/ {print $2}')
if [[ -z "$BYTES" ]]; then
    echo "❌ SMA.s0.g_bytes ei löytynyt. Onko malloc käytössä?"
    exit 1
fi

# Lue RSS-arvo /proc tiedostosta
RSS_KB=$(grep VmRSS /proc/$PID/status | awk '{print $2}')
if [[ -z "$RSS_KB" ]]; then
    echo "❌ VmRSS-arvoa ei saatu luettua."
    exit 1
fi

RSS_BYTES=$((RSS_KB * 1024))

# Lasketaan suhdeluku
RATIO=$(awk "BEGIN {printf \"%.2f\", $RSS_BYTES / $BYTES}")

# Näytetään tulokset
echo "🧠 Cache (SMA.s0.g_bytes): $BYTES bytes ($(numfmt --to=iec $BYTES))"
echo "📦 RSS (todellinen RAM-käyttö): $RSS_BYTES bytes ($(numfmt --to=iec $RSS_BYTES))"
echo "📊 Suhde (RAM / cache): $RATIO ×"

# Suositeltava tarkasteluväli 1x – 3x riippuen objektikoon hajonnasta
