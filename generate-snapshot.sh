#!/bin/bash

# Snapshot-tallennushakemisto
TARGET_DIR="/var/www/emergency/katiska/www.katiska.eu"

# Pääsivuston osoite
BASE_URL="https://www.katiska.eu"
SITEMAP_INDEX="$BASE_URL/sitemap_index.xml"

# Luo väliaikaishakemisto
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Poimi alisitemapit
echo "Ladataan sitemap_index.xml ja poimitaan alisitemapit..."
curl -s "$SITEMAP_INDEX" | grep -oP '(?<=<loc>)[^<]+' > "$TMPDIR/sitemaps.txt"

> "$TMPDIR/urls.txt"

# Käydään jokainen alisitemap läpi ja kerätään varsinaiset URLit
echo "Poimitaan kaikki varsinaiset URLit alisitemapeista..."
while read -r sitemap; do
    echo "  → $sitemap"
    curl -s "$sitemap" | grep -oP '(?<=<loc>)[^<]+' >> "$TMPDIR/urls.txt"
done < "$TMPDIR/sitemaps.txt"

# Ladataan sivut snapshotiksi
echo "Ladataan snapshotit (sivumäärä: $(wc -l < "$TMPDIR/urls.txt"))..."
wget \
  --input-file="$TMPDIR/urls.txt" \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  --span-hosts \
  --domains=www.katiska.eu,cdn.katiska.eu \
  --header="X-Bypass-Cache: 1" \
  --header="User-Agent:SnapshotWarmer/1.0" \
  --execute robots=off \
  --wait=1 \
  --random-wait \
  --timeout=5 \
  --tries=3 \
  --directory-prefix="$TARGET_DIR"

echo "✅ Snapshot luotu kohteeseen: $TARGET_DIR"
