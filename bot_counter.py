#!/usr/bin/env python3

# Varnish must detect user agents and log bots using BOT_DETECTED

import subprocess
from collections import Counter
import re

# Finding BOT_DETECTED from varnishlog
cmd = [
    "varnishlog",
    "-g", "request",
    "-q", 'VCL_Log ~ "BOT_DETECTED"',
    "-n", "varnishd",  # change if/when different workdir
    "-d", "-t", "1800"   # Collecting 60 seconds
]

print("Analyzing BOT_DETECTED-requests...")

# Using varnishlog and parsing IPs
proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

ip_pattern = re.compile(r'BOT_DETECTED.*IP=(\d+\.\d+\.\d+\.\d+)')
ips = ip_pattern.findall(proc.stdout)

counter = Counter(ips)

# Show resutls and suggest banning
for ip, count in counter.items():
    if count >= 3:
        print(f"🚨 IP {ip} detected {count} times inside udes timeframe. Perhaps it should be banned.")
    else:
        print(f"IP {ip} detected {count} kertaa — no need to react.")
