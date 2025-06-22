#!/bin/bash

# Nicknames, urls and snapshot directories
case "$1" in
  example)
    DOMAIN="www.example.com"
    TARGET_DIR="/var/www/emergency/example"
    ;;
  try)
    DOMAIN="try.example.tld"
    TARGET_DIR="/var/www/emergency/try"
    ;;
  third)
    DOMAIN="www.example.invalid"
    TARGET_DIR="/var/www/emergency/third"
    ;;
  *)
    echo "❌ Unknown site: $1"
    echo "Usage: $0 {example|try|third}"
    exit 1
    ;;
esac

BASE_URL="https://$DOMAIN"
SITEMAP_INDEX="$BASE_URL/sitemap_index.xml"

# Create temp dir
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Loading sitemap_index.xml: $SITEMAP_INDEX"
curl -s "$SITEMAP_INDEX" | grep -oP '(?<=<loc>)[^<]+' > "$TMPDIR/sitemaps.txt"

> "$TMPDIR/urls.txt"
echo "Picking urls from sub-sitemaps..."
while read -r sitemap; do
    echo "  → $sitemap"
    curl -s "$sitemap" | grep -oP '(?<=<loc>)[^<]+' >> "$TMPDIR/urls.txt"
done < "$TMPDIR/sitemaps.txt"

echo "📥 loading snapshot, ($(wc -l < "$TMPDIR/urls.txt") URLs)..."
wget \
  --input-file="$TMPDIR/urls.txt" \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  --span-hosts \
  --domains=$DOMAIN,cdn.$DOMAIN \
  --header="X-Bypass-Cache: 1" \
  --header="User-Agent:SnapshotWarmer/1.0" \
  --execute robots=off \
  --wait=1 \
  --random-wait \
  --timeout=5 \
  --tries=3 \
  --directory-prefix="$TARGET_DIR"

echo "✅ Snapshot created: $TARGET_DIR"
