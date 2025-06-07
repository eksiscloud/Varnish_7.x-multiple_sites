sub trusted {

	## Replacement for whitelist acl
	## Is this needed? Not ne essary, but this is cleaner

    # Whitelisted IPs
    if (
        req.http.X-Real-IP == "157.180.74.208" ||
        req.http.X-Real-IP == "85.76.112.42"
    ) {
        return(true);
    }

    # Local use
    if (req.http.X-Real-IP == "127.0.0.1") {
        return(true);
    }

    # Everybody else
    return(false);

# That's it here
}
