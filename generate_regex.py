#!/usr/bin/env python3

import os
import re
from pathlib import Path

# Default directories
INPUT_DIR = Path("inputs")
OUTPUT_DIR = Path("ext")

# Cleaning regex
def escape_vcl_regex(p):
    if p.startswith('\\') or '*' in p or '[' in p or '(' in p:
        return p  # assuming it is already regex
    return re.escape(p)

# Create  match_*.vcl
def generate_vcl_block(name, patterns):
    escaped = [escape_vcl_regex(p) for p in patterns]
    joined = "|".join(escaped)

    return f'''
sub match_{name} {{
    if (req.url ~ "^/({joined})") {{
        if (req.http.X-County-Code ~ "fi" || req.http.X-Language ~ "fi") {{
            return (synth(403, "Forbidden"));
        }} else {{
            return (synth(666, "Security issue"));
        }}
    }}
}}
'''.strip()

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for file in INPUT_DIR.glob("*.txt"):
        base_name = file.stem
        with file.open("r", encoding="utf-8") as f:
            patterns = [line.strip() for line in f if line.strip()]

        vcl_code = generate_vcl_block(base_name, patterns)
        output_file = OUTPUT_DIR / f"match_{base_name}.vcl"
        with output_file.open("w", encoding="utf-8") as f:
            f.write(vcl_code)

    print("✅ match_*.vcl generated. Create and edit 'malicious_url.vcl' manually using wanted call order.")

if __name__ == "__main__":
    main()
