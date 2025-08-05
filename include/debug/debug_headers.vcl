sub debug_headers {
    if (req.http.X-Match) {
        set resp.http.X-Match = req.http.X-Match;
    }

    if (req.http.X-ASN) {
        set resp.http.X-ASN = req.http.X-ASN;
    } else {
        set resp.http.X-ASN = "missing";
    }

    if (req.http.Accept-Language) {
        set resp.http.X-Language = req.http.Accept-Language;
    } else {
        set resp.http.X-Language = "missing";
    }

    set resp.http.X-Debug = "403-from-varnish";
}
