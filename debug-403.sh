#!/bin/bash

echo "🕵️ Yhteenveto kaikista 403-vastauksista:"
echo

varnishlog -g request -q 'RespStatus == 403' \
  -i ReqURL,RespStatus,RespHeader \
  | awk '
    /^-   ReqURL/ {
        url = $3
    }

    /^-   RespHeader/ {
        if ($0 ~ /X-Match:/) {
            match($0, /X-Match: (.*)$/, m)
            match_val = m[1]
        }
        if ($0 ~ /X-ASN:/) {
            match($0, /X-ASN: (.*)$/, m)
            asn_val = m[1]
        }
        if ($0 ~ /X-Language:/) {
            match($0, /X-Language: (.*)$/, m)
            lang_val = m[1]
        }
    }

    /^$/ && url != "" {
        print "🔸 URL:      " url
        print "    X-Match:   " (match_val ? match_val : "n/a")
        print "    X-ASN:     " (asn_val ? asn_val : "n/a")
        print "    Language:  " (lang_val ? lang_val : "n/a")
        print "--------------------------"

        # Nollataan tilat
        url = ""; match_val = ""; asn_val = ""; lang_val = "";
    }
'
