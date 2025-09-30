#!/bin/bash

# Timestamp for versioning
timestamp=$(date +"%Y%m%d_%H%M%S")

# Common VCL
vclfile="/etc/varnish/sites/onion.vcl"

# Sites using onion.vcl
sites=(
  "onion-eksis"
  "onion-jagster"
  "onion-katiska"
  "onion-poochie"
)

# CLI connection params
VARNISHADM="varnishadm -T localhost:6082 -S /etc/varnish/secret -t 30"

# Function to run varnishadm with retry on CLI communication error (hdr)
run_varnishadm() {
    local cmd="$1"
    local attempts=0
    local max_attempts=2

    while (( attempts < max_attempts )); do
        output=$($VARNISHADM $cmd 2>&1)
        if echo "$output" | grep -q "CLI communication error (hdr)"; then
            ((attempts++))
            if (( attempts < max_attempts )); then
                echo "⚠ CLI error (hdr), retrying in 0.5s..."
                sleep 0.5
                continue
            else
                echo "❌ ERROR after $max_attempts attempts: $cmd"
                return 1
            fi
        fi
        echo "$output"
        return 0
    done
}

echo "🔍 Checking VCL syntax: $vclfile"
if ! varnishd -Cf "$vclfile" > /dev/null 2>&1; then
    echo "❌ ERROR: Syntax error in VCL. Deploy cancelled."
    exit 1
fi
echo "✅ Syntax OK"

# Small pause before loads
sleep 0.2

# Loop through sites
for site in "${sites[@]}"; do
    vclname="${site}_${timestamp}"
    echo
    echo "==> Load for $site → $vclname"

    if ! run_varnishadm "vcl.load $vclname $vclfile"; then
        continue
    fi

    sleep 0.1

    if ! run_varnishadm "vcl.label $site $vclname"; then
        continue
    fi

    echo "✓ Label set: $site → $vclname"
done

echo "✅ All is ready. Checkout the status: varnishadm vcl.list"
echo "# The cosmetic line hell remained undefeated. Varnishadm 1 – Aesthetics 0."
