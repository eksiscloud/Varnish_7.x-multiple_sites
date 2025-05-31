#!/bin/bash

# Basically it do varnisdm vcl.discard *
# Usage:
# ./vcl-discard.sh -> everything than warm ones
# ./vcl-discard.sh --keep-latest -> keeps latest cold ones too

KEEP_LATEST=false

# Checking arguments
if [[ "$1" == "--keep-latest" ]]; then
    KEEP_LATEST=true
fi

# Getting every cold & available & labels==0
# Building CSV: name, temperature, time from name (if there is date in the end)
vcl_list=$(varnishadm vcl.list -j | jq -r '
    map(select(
        type == "object" and
        .status == "available" and
        .temperature == "cold" and
        (.labels // 0) == 0
    )) |
    .[] |
    .name
')

if [ -z "$vcl_list" ]; then
    echo "✅ No removable VCLs (cold & labels==0)."
    exit 0
fi

# If --keep-latest, filtering the most freshest one from every group
if $KEEP_LATEST; then
    # Groupimg by prefix (before underlime) amd keeping everything _else_ than the newest one
    vcl_to_discard=$(echo "$vcl_list" | awk -F_ '
        {
            if (NF >= 2) {
                prefix = $1
                timestamp = $(NF)
                group[prefix][$0] = timestamp
            } else {
                misc[$0] = 1
            }
        }
        END {
            # Remove everything from every group, except the biggest timestamp
            for (p in group) {
                max = ""
                for (vcl in group[p]) {
                    t = group[p][vcl]
                    if (t > max) {
                        max = t
                        newest = vcl
                    }
                }
                for (vcl in group[p]) {
                    if (vcl != newest)
                        print vcl
                }
            }
            for (vcl in misc)
                print vcl
        }
    ')
else
    vcl_to_discard="$vcl_list"
fi

if [ -z "$vcl_to_discard" ]; then
    echo "✅ Nothing to discard (--keep-latest filtering)."
    exit 0
fi

# Show the list to user
echo "🧹 Following VCLs will be removed:"
echo "$vcl_to_discard" | sed 's/^/ - /'
echo
read -p "❗ Are you sure these should be discarded? (y/N) " confirm
echo

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    while read -r vcl; do
        echo "🧹 Discarding: $vcl"
        if ! varnishadm vcl.discard "$vcl"; then
            echo "⚠️ Error: couldn't remove $vcl"
        fi
    done <<< "$vcl_to_discard"
    echo "✅ Discarding ready."
else
    echo "🚫 Discarding interrupted."
fi
