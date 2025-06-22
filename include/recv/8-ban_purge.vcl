sub ban_purge-8 {
 
   
   if (req.method != "BAN" && req.method != "PURGE" && req.method != "REFRESH") {
        return;
    }

    ## Normal no-go rules
    if (req.http.X-Bypass != "true") {
        return(synth(405, "Forbidden"));
    }

    if (!req.http.xkey-purge) {
        return(synth(400, "Missing xkey"));
    }

    ## Use only allowed xkey-tags
    if (
        req.http.xkey-purge !~ "^frontpage$" &&
        req.http.xkey-purge !~ "^sidebar$" &&
        req.http.xkey-purge !~ "^url-.*" &&
        req.http.xkey-purge !~ "^article-[0-9]+$"
       ) {
	    std.log("⛔ Unknown xkey: " + req.http.xkey-purge);
            return(synth(404, "Unknown xkey tag: " + req.http.xkey-purge));
    }

    ## When BAN happens
    if (req.method == "BAN") {
        ban("obj.http.xkey ~ " + req.http.X-Cache-Tags);
        return(synth(200, "Banned: " + req.http.X-Cache-Tags));
    }

    # Using hard PURGE for xkey-urls
    if (req.method == "PURGE") {
        if (req.http.xkey-purge && req.http.xkey-purge ~ "^url-") {
            xkey.purge(req.http.xkey-purge);
            return(synth(200, "Hard purged: " + req.http.xkey-purge));
        }

        # Soft fallback-purge
        ban("obj.http.xkey ~ " + req.http.xkey-purge);
        return(synth(200, "Soft purged: " + req.http.xkey-purge));
    }

    ## REFRESH or another PURGE
    return(hash);
}
