#!/usr/bin/env python3

# First:
# varnishlog -g request -i BereqURL,BerespStatus,BerespHeader,VCL_call,VCL_return > /tmp/varnishlog.txt

import re
from collections import defaultdict

# Syötetiedoston nimi
logfile = "/tmp/varnishlog.txt"

# Tiedonkeruu
uncacheable_reasons = defaultdict(list)

with open(logfile, encoding="utf-8") as f:
    current_url = None
    current_reason = set()
    for line in f:
        line = line.strip()

        if line.startswith("-- BereqURL"):
            current_url = line.split(None, 1)[1]
            current_reason = set()

        elif "Set-Cookie" in line:
            if current_url:
                current_reason.add("Set-Cookie")

        elif "Cache-Control" in line and "no-store" in line:
            if current_url:
                current_reason.add("no-store")

        elif line.startswith("-- VCL_call") and "BACKEND_RESPONSE" in line:
            # Kun BACKEND_RESPONSE saapuu, talletetaan tiedot
            for reason in current_reason:
                uncacheable_reasons[reason].append(current_url)
            current_url = None
            current_reason = set()

# Tulostus
print("📊 Uncacheable yhteenveto:\n")

total = 0
for reason, urls in uncacheable_reasons.items():
    print(f"{reason}: {len(urls)} kpl")
    total += len(urls)

print(f"\nYhteensä: {total} uncacheable vastausta.\n")

# Yksityiskohtaiset URL:t (valinnainen)
print("🔍 Esimerkkejä uncacheable URL:ista:")
for reason, urls in uncacheable_reasons.items():
    print(f"\n⟶ {reason}:")
    for url in sorted(set(urls))[:10]:  # max 10 / syy
        print(f"   - {url}")
