#!/bin/bash

# Snapshot-saving directory
TARGET_DIR="/var/www/emergency/example/www.example.tld"

# The address of the site
BASE_URL="https://www.example.tld"
SITEMAP_INDEX="$BASE_URL/sitemap_index.xml"

# Create temp directory
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Get sub-sitemaps
echo "Loading sitemap_index.xml and fetching sub-sitemaps..."
curl -s "$SITEMAP_INDEX" | grep -oP '(?<=<loc>)[^<]+' > "$TMPDIR/sitemaps.txt"

> "$TMPDIR/urls.txt"

# Picking up every real urls from sub-sitemaps
echo "Gettimg every actual urls from sub-sitemaps..."
while read -r sitemap; do
    echo "  → $sitemap"
    curl -s "$sitemap" | grep -oP '(?<=<loc>)[^<]+' >> "$TMPDIR/urls.txt"
done < "$TMPDIR/sitemaps.txt"

# Loadimg pages to snapshot
echo "Loadimg snapshots (pages: $(wc -l < "$TMPDIR/urls.txt"))..."
wget \
  --input-file="$TMPDIR/urls.txt" \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  --span-hosts \
  --domains=www.example.tld,cdn.example.tld \
  --header="X-Bypass-Cache: 1" \
  --header="User-Agent:SnapshotWarmer/1.0" \
  --execute robots=off \
  --wait=1 \
  --random-wait \
  --timeout=5 \
  --tries=3 \
  --directory-prefix="$TARGET_DIR"

echo "✅ Snapshot ceeated: $TARGET_DIR"
