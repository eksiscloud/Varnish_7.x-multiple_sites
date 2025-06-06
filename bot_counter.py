#!/usr/bin/env python3

import subprocess
from collections import Counter
import re

# Ajetaan varnishlog suoraan ja haetaan BOT_DETECTED rivit
cmd = [
    "varnishlog",
    "-g", "request",
    "-q", 'VCL_Log ~ "BOT_DETECTED"',
    "-n", "default",  # Vaihda jos eri nimi
    "-d", "-t", "600"   # Kerää 60 sekunnin ajan
]

print("Analysoidaan BOT_DETECTED-pyyntöjä asetusten ajan mukaan...")

# Ajetaan varnishlog ja parsitaan IP:t
proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

ip_pattern = re.compile(r'BOT_DETECTED.*IP=(\d+\.\d+\.\d+\.\d+)')
ips = ip_pattern.findall(proc.stdout)

counter = Counter(ips)

# Näytä tulokset ja ehdota estoa
for ip, count in counter.items():
    if count >= 3:
        print(f"🚨 IP {ip} havaittu {count} kertaa viimeisen minuutin aikana. Kannattaa harkita estoa.")
    else:
        print(f"IP {ip} havaittu {count} kertaa — ei reaktiota.")
