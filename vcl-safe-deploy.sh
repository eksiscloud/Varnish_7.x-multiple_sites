#!/bin/bash

# Timestamp for versioning
timestamp=$(date +"%Y%m%d_%H%M%S")

# Common VCL
vclfile="/etc/varnish/sites/shared_wp.vcl"

# Sites using shared_wp.vcl:ää
sites=(
  "katiska"
  "poochie"
  "jagster"
  "eksis"
  "selko"
  "dev"
)

# Ensin tarkistetaan syntaksi
echo "🔍 Check VCL-syntax: $vclfile"

if ! varnishd -Cf "$vclfile" > /dev/null 2>&1; then
    echo "❌ ERROR: A syntax error in VCL. Deploy cancelled."
    exit 1
fi

echo "✅ Syntax OK. Continuing deploy..."

# Load and label for every site
for site in "${sites[@]}"; do
    vclname="${site}_${timestamp}"
    echo "==> Update $site → $vclname"

    if varnishadm vcl.load "$vclname" "$vclfile"; then
        varnishadm vcl.label "$site" "$vclname"
        echo "✓ Label has set: $site → $vclname"
    else
        echo "✗ ERROR: VCL loading failed for $site"
    fi
done

echo "✅ All is ready. Checkout the status: varnishadm vcl.list"
