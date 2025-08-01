sub snapshot-2 {

	### vcl_backend_respone, second part

	## Snapshot routines 

	# Wordpress is down, let's start snapshot route
	if (beresp.status == 500) {
		std.syslog(180, "Backend: error  HTTP 500 – move to vcl_backend_error");
		return (fail);
	}

        # One really stranger thing where backend can tell 503, let's start snapshot route
        if (beresp.status == 503) {
                std.syslog(180, "Backend: error  HTTP 503 – move to vcl_backend_error");
                return (fail);
        }

        # Backend has gateway issue, let's start snapshot route
        if (beresp.status == 504) {
                std.syslog(180, "Backend: error  HTTP 504 – move to vcl_backend_error");
                return (fail);
        }

	# If backend is down we move to snapshot backend that serves static content, when not in cache.
	# But Varnish uses 200 OK, because it got content, but we don't want to tell to bots that temp content is 200
	if (bereq.backend == snapshot && beresp.status == 200) {
		std.log(">> Snapshot backend responded 200 — rewriting to 302");
		set beresp.status = 302;
		set beresp.reason = "Service Unavailable (snapshot)";
	}

	# If there was an backend error (500/502/503/504) where backend can give a response
	if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {

        	# If this was a background fetch (i.e. after grace delivering), abandon
		if (bereq.is_bgfetch) {
			std.syslog(180, "Backend failure, abandoning bgfetch for " + bereq.url);
			return(abandon);
		}

        	# Stop cache only if not in snapshot backend
		if (bereq.backend != snapshot) {
			std.syslog(180, "Backend failure, marking response uncacheable: " + bereq.http.host + bereq.url);
			set beresp.uncacheable = true;
		}
	}

## The end is here
}
