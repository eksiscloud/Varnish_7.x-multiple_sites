#!/usr/bin/env python3

# First:
# varnishlog -g request -i BereqURL,BerespStatus,BerespHeader,VCL_call,VCL_return > /tmp/varnishlog.txt
# varnishlog -g request -i BereqURL,BerespHeader,BerespStatus,VCL_call,VCL_return | /tmp/varnishlog.txt

import sys
from collections import defaultdict

# ./analyze_uncacheables.py < /tmp/varnishlog.txt
uncacheable_entries = []
current_url = None
current_block = []
inside_request = False

for line in sys.stdin:
    line = line.strip()

    if line.startswith("*   << Request"):
        inside_request = True
        current_block = []
        current_url = None

    elif inside_request:
        current_block.append(line)

        if line.startswith("-- BereqURL"):
            current_url = line.split(None, 1)[1]

        elif line.startswith("**  << BeReq") or line.startswith("*   << Request  >>"):
            continue

        elif line.startswith("**  <<"):
            # New block -> process old one
            inside_request = False
            for l in current_block:
                if "beresp.uncacheable = true" in l:
                    uncacheable_entries.append((current_url, list(current_block)))
            current_block = []

# Analyze
reason_summary = defaultdict(int)
reason_by_url = defaultdict(list)

for url, block in uncacheable_entries:
    reason = []

    for line in block:
        if "Set-Cookie" in line:
            reason.append("Set-Cookie")
        elif "Cache-Control" in line and "no-store" in line:
            reason.append("Cache-Control: no-store")
        elif "return(pass)" in line:
            reason.append("return(pass)")
        elif "return(pipe)" in line:
            reason.append("return(pipe)")
        elif "beresp.uncacheable = true" in line:
            reason.append("uncacheable")

    final_reason = ", ".join(sorted(set(reason))) if reason else "unkown"
    reason_summary[final_reason] += 1
    reason_by_url[url].append(final_reason)

# Summary
print("== SUMMARY ==")
for reason, count in reason_summary.items():
    print(f"{reason}: {count} times")

print("\n== Individual URLs and reasons ==")
for url, reasons in reason_by_url.items():
    print(f"{url} → {', '.join(reasons)}")
