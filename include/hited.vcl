sub hitit {

	### Whole vcl_hit

    if (obj.uncacheable) {
        return (pass);
    }

    ## Normal hit
    set req.http.x-cache = "hit";

    ## Grace-hit: TTL is ended, but is under grace
    if (obj.ttl <= 0s && obj.grace > 0s) {
        std.log("🟡 HIT grace: " + req.url);
        set req.http.x-cache = "hit graced";
        return (deliver);
    }

    ## Banned or totally stale
    if (obj.ttl <= 0s && obj.grace <= 0s) {
        std.log("💥 Banned HIT: " + req.url +
            " — xkey: " + obj.http.xkey +
            " — UA: " + req.http.User-Agent);
        # Get a fresh copy
        return (miss);
    }

    return (deliver);

## The end of this road
}
