#!/bin/bash

## Use when every site has its own vcl

# Timestamp for versioning
timestamp=$(date +"%Y%m%d_%H%M%S")

# Sites and vcls, must ne same load than in start.cli
declare -A vclmap=(
    [poochie]="/etc/varnish/sites/shared_wp.vcl"
    [dev]="/etc/varnish/sites/shared_wp.vcl"
    [jagster]="/etc/varnish/sites/shared_wp.vcl"
    [eksis]="/etc/varnish/sites/shared_wp.vcl"
    [selko]="/etc/varnish/sites/shared_wp.vcl"
    [katiska]="/etc/varnish/sites/shared_wp.vcl"
)

for site in "${!vclmap[@]}"; do
    vclfile="${vclmap[$site]}"
    vclname="${site}_${timestamp}"

    echo "==> Update $site (tiedosto: $vclfile → label: $site)"

    if varnishadm vcl.load "$vclname" "$vclfile"; then
        varnishadm vcl.label "$site" "$vclname"
        echo "✓ Label updated: $site → $vclname"
    else
        echo "✗ ERROR: Loading VCL failed for $site"
    fi
done

echo "==> Check the situation: varnishadm vcl.list"
