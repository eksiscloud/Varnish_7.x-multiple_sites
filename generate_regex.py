import os
import re

# chmod +x

INPUT_DIR = "inputs"
OUTPUT_DIR = "includes"

# For sanitation
def escape_vcl_regex(p):
    if p.startswith('\\') or '*' in p or '[' in p or '(' in p:
        return p  # finished regex
    return re.escape(p)

def generate_vcl_block(name, patterns):
    escaped = [escape_vcl_regex(p) for p in patterns]
    joined = "|".join(escaped)
    return f"""
sub match_{name} {{
    if (req.url ~ "^/({joined})") {{
        set req.http.X-Match = "1";
    }}
}}
""".strip()

def generate_master_block(subs):
    lines = ["sub is_malicious_url {"]
    for s in subs:
        lines.append(f"    call match_{s};")
    lines.append("}")
    return "\n".join(lines)

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    sub_names = []

    for filename in os.listdir(INPUT_DIR):
        if not filename.endswith(".txt"):
            continue

        base_name = os.path.splitext(filename)[0]  # i.e. url_attacks
        sub_names.append(base_name)

        with open(os.path.join(INPUT_DIR, filename), 'r', encoding='utf-8') as f:
            patterns = [line.strip() for line in f if line.strip()]

        vcl_code = generate_vcl_block(base_name, patterns)
        output_file = os.path.join(OUTPUT_DIR, f"match_{base_name}.vcl")

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(vcl_code)

    # Create main function
    master_vcl = generate_master_block(sub_names)
    with open(os.path.join(OUTPUT_DIR, "malicious_url.vcl"), 'w', encoding='utf-8') as f:
        f.write(master_vcl)

    print("✅ All VCL-files are generated succesfully.")

if __name__ == "__main__":
    main()
