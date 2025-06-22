sub hitit {

	### Whole vcl_hit

    ## Pure hit
    if (obj.ttl >= 0s) {
        set req.http.x-cache = "hit";
        return (deliver);
    }

    ## Out of TTL, but is under grace
    if (obj.ttl <= 0s && obj.grace > 0s) {
        set req.http.x-cache = "hit graced";
        std.log("🟡 HIT grace: " + req.url);
        return (deliver);
    }

    ## Banned or badly stale
    std.log("💥 Banned HIT, fetch fresh copy: " + req.url);
    return (pass);


## The end of this road
}
