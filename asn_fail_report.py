#!/usr/bin/env python3

import sys
import re
import pandas as pd
import geoip2.database
from collections import defaultdict

# ASN-database
DEFAULT_MMDB = "/usr/share/GeoIP/GeoLite2-ASN.mmdb"

def parse_log_line(line):
    match = re.search(r'(?P<ip>\d+\.\d+\.\d+\.\d+)\s+[A-Z]{2}\s+-\s+\[.*?\]\s+"[A-Z]+\s+.*?"\s+(?P<status>\d{3})\s+', line)
    if match:
        return match.group("ip"), int(match.group("status"))
    return None, None

def main(logfile_path, mmdb_path, output_csv):
    reader = geoip2.database.Reader(mmdb_path)
    data = defaultdict(lambda: {"total": 0, "success": 0})

    with open(logfile_path, "r", encoding="utf-8") as f:
        for line in f:
            ip, status = parse_log_line(line)
            if not ip:
                continue
            try:
                asn_info = reader.asn(ip)
                asn_name = f"{asn_info.autonomous_system_number} {asn_info.autonomous_system_organization}"
            except Exception:
                asn_name = "UNKNOWN"

            data[asn_name]["total"] += 1
            if status == 200:
                data[asn_name]["success"] += 1

    reader.close()

    df = pd.DataFrame([
        {"ASN": asn, "Requests": counts["total"], "Success_200": counts["success"]}
        for asn, counts in data.items()
        if counts["success"] == 0
    ])

    df.sort_values(by="Requests", ascending=False, inplace=True)
    df.to_csv(output_csv, index=False)
    print(f"✔️ Saved report to: {output_csv}")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        logfile_path = sys.argv[1]
        mmdb_path = DEFAULT_MMDB
        output_csv = sys.argv[2]
    elif len(sys.argv) == 4:
        logfile_path = sys.argv[1]
        mmdb_path = sys.argv[2]
        output_csv = sys.argv[3]
    else:
        print("Usage:")
        print("  ./asn_fail_report_geo.py /path/to/access.log output.csv")
        print("  ./asn_fail_report_geo.py /path/to/access.log /path/to/GeoLite2-ASN.mmdb output.csv")
        sys.exit(1)
    main(logfile_path, mmdb_path, output_csv)
