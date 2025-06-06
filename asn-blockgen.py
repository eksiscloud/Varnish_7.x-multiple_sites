#!/usr/bin/env python3
import csv
import sys
import os

def generate_vcl(csv_path, output_path):
    try:
        with open(csv_path, newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            blocks = [
                "sub asn_blocklist {\n\n# AUTOGENERATED ASN BLOCKLIST\n# DO NOT EDIT MANUALLY\n"
            ]
            for row in reader:
                asn_id_full = row["ASN"].strip()
                asn_id = asn_id_full.split()[0]  # Poimitaan numeerinen osa
                description = row["Requests"].strip()
                block = f"""    if (req.http.X-ASN-ID == "{asn_id}") {{
        set req.http.X-Match = "asn-as{asn_id}";
        std.log("ASN ID match: " + req.http.X-ASN-ID + " IP: " + req.http.X-Real-IP + " country:" + req.http.X-Country-Code);
        return (synth(466, "Blocked ASN: {description} (AS{asn_id})"));
    }}"""
                blocks.append(block)
            blocks.append("}")  # sulkeva aaltosulje subille

        with open(output_path, "w", encoding='utf-8') as vclfile:
            vclfile.write("\n\n".join(blocks))

        os.chmod(output_path, 0o644)
        print(f"✅ VCL generated: {output_path}")
    except Exception as e:
        print(f"❌ ERROR: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ./asn-blockgen.py input.csv output.vcl")
        sys.exit(1)

    csv_path = sys.argv[1]
    output_path = sys.argv[2]
    generate_vcl(csv_path, output_path)
