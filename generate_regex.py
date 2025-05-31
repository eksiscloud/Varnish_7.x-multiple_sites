#!/usr/bin/env python3

import os
import re
from pathlib import Path

# Directories
INPUT_DIR = Path("inputs")
OUTPUT_DIR = Path("ext")

# Cleans single pattern and decides classification
def escape_vcl_regex(p):
    p = p.strip()
    # If pattern seems to be regex
    if p.startswith('^') or p.endswith('$') or any(c in p for c in ['\\', '*', '[', '(', '|']):
        return p
    # If pattern looks like a files
    if re.match(r'^\.?[a-zA-Z0-9_\-]+\.[a-z0-9]+$', p):
        return re.escape(p) + r'$'
    # Of pattern starts with / assume it os start of a path (that's actually wrong)
    if p.startswith('/'):
        return re.escape(p)
    # Otherwise, look from everywhere in path
    return r'.*' + re.escape(p) + r'.*'

# Create single  match_*.vcl
def generate_vcl_block(name, patterns):
    escaped_patterns = [escape_vcl_regex(p) for p in patterns]
    joined = "|".join(escaped_patterns)

    return f'''
sub match_{name} {{
    if (req.url ~ "({joined})") {{
        if (req.http.X-Country-Code ~ "fi" || req.http.X-Accept-Language ~ "fi") {{
            return (synth(403, "Forbidden"));
        }} else {{
            return (synth(666, "Security issue"));
        }}
    }}
}}
'''.strip()

# Do main function
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
