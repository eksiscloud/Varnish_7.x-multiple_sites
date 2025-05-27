#!/bin/bash

# One shot script I used to extract urls from 403.vcl to nowadays plain text input.

# Or you can do 
# sed -n 's/.*req\.url ~ "\([^"]*\)".*/\1/p' path/old.vcl

SOURCE_VCL="ext/403.vcl"  # change right source
OUTDIR="inputs"        # destination dir

mkdir -p "$OUTDIR"

# Pick all URL-attackpaths
sed -n 's/.*req\.url ~ "\([^"]*\)".*/\1/p' "$SOURCE_VCL" > "$OUTDIR"/all_attacks.txt

# Delete old files
rm -f "$OUTDIR"/*_attack.txt

# classify per attack type
grep -i "^/xmlrpc"         "$OUTDIR"/all_attacks.txt > "$OUTDIR"/xmlrpc_attack.txt
grep -i "^/wp-"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/wp_attack.txt
grep -i "^/cgi-bin"        "$OUTDIR"/all_attacks.txt > "$OUTDIR"/cgi_attack.txt
grep -i "\.env"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/env_attack.txt
grep -i "phpmyadmin"       "$OUTDIR"/all_attacks.txt > "$OUTDIR"/phpmyadmin_attack.txt
grep -i "config"           "$OUTDIR"/all_attacks.txt > "$OUTDIR"/config_attack.txt
grep -i "\.git"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/git_attack.txt
grep -i "\.sql"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/sql_attack.txt
grep -i "\.php"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/php_attack.txt
grep -i "\.bak"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/bak_attack.txt
grep -i "\.zip"            "$OUTDIR"/all_attacks.txt > "$OUTDIR"/zip_attack.txt

# Rest ones
comm -23 <(sort "$OUTDIR"/all_attacks.txt | uniq) \
         <(cat "$OUTDIR"/*_attack.txt | sort | uniq) > "$OUTDIR"/other_attack.txt

echo "✅ Ready! Attack-URLs are saved in the directory: $OUTDIR/"
