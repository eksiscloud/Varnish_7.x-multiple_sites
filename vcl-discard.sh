#!/bin/bash

# Basically do varnisdm vcl.discard *
# Usage:
# ./vcl-discard.sh -> everything than warm ones
# ./vcl-discard.sh --keep-latest -> keeps latest cold ones too

KEEP_LATEST=false

# Tarkistetaan argumentit
if [[ "$1" == "--keep-latest" ]]; then
    KEEP_LATEST=true
fi

# Haetaan kaikki cold & available & labels==0
# Rakennetaan CSV-muoto: nimi, lämpötila, aika-arvio nimestä (jos löytyy päivämäärä lopusta)
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
    echo "✅ Ei poistettavia VCL:iä (cold & labels==0)."
    exit 0
fi

# Jos --keep-latest, suodatetaan tuorein jokaisesta ryhmästä pois
if $KEEP_LATEST; then
    # Ryhmitetään nimen etuliitteen (ennen alaviivaa) mukaan ja pidetään vain kaikki _muut_ kuin uusin
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
            # Poistetaan jokaisesta ryhmästä kaikki paitsi suurin aikaleima
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
    echo "✅ Ei discardattavaa (--keep-latest suodatettu)."
    exit 0
fi

# Näytetään käyttäjälle lista
echo "🧹 Seuraavat VCL:t poistetaan:"
echo "$vcl_to_discard" | sed 's/^/ - /'
echo
read -p "❗ Haluatko varmasti poistaa nämä? (y/N) " confirm
echo

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    while read -r vcl; do
        echo "🧹 Discardataan: $vcl"
        if ! varnishadm vcl.discard "$vcl"; then
            echo "⚠️  Virhe: ei voitu poistaa $vcl"
        fi
    done <<< "$vcl_to_discard"
    echo "✅ Poisto valmis."
else
    echo "🚫 Poisto keskeytetty."
fi
