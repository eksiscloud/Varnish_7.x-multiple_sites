sub be_started {

	### vcl_backend_respone, first part

	## Add name of backend in varnishncsa log. The name is shown only if backend responds.
	# You can find slow replying backends (over 3 sec) with that:
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' | awk '$7 > 3 {print}'
	# or
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' -q "Timestamp:Beresp[3] > 3 or Timestamp:Error[3] > 3"
	std.log("backend: " + beresp.backend.name);

	## Let's create a couple helpful tag'ish
	set beresp.http.x-url = bereq.url;
	set beresp.http.x-host = bereq.http.host;
	
	## Will kick in if backend is sick
	if (bereq.url ~ "^/wp-json/" || bereq.url ~ "^/wp-admin/") {
		# no grace for admins
		set beresp.grace = 0s;
	} else {
	        set beresp.grace = 12h;
	}

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

	# if backend is down we move to snapshot backend that serves static content, when not in cache
	# Few things must  be changed then
	# Varnish uses 200 OK, because it got content, but we don't want to tell to bits that temporary content is 200
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
			std.syslog(180, "Backend failure, marking response uncacheable: " + bereq.url);
			set beresp.uncacheable = true;
		}
	}

    ## Set xkey
    if (beresp.http.X-Cache-Tags) {
        set beresp.http.xkey = beresp.http.X-Cache-Tags;
    }

    ## Add domain-xkey if not already there
    if (bereq.http.host) {
        if (bereq.http.host == "www.katiska.eu" && !std.strstr(beresp.http.xkey, "domain-katiska")) {
            set beresp.http.xkey += ",domain-katiska";
        } else if (bereq.http.host == "www.poochierevival.info" && !std.strstr(beresp.http.xkey, "domain-poochie")) {
            set beresp.http.xkey += ",domain-poochie";
        } else if (bereq.http.host == "www.eksis.one" && !std.strstr(beresp.http.xkey, "domain-eksis")) {
            set beresp.http.xkey += ",domain-eksis";
        } else if (bereq.http.host == "jagster.eksis.one" && !std.strstr(beresp.http.xkey, "domain-jagster")) {
            set beresp.http.xkey += ",domain-jagster";
        } else if (bereq.http.host == "dev.eksis.one" && !std.strstr(beresp.http.xkey, "domain-dev")) {
            set beresp.http.xkey += ",domain-dev";
        }
    }

    ## Add xkey for tags if not already there
    if (bereq.url ~ "^/") {
        # This trick must be done beacuse strings can't be joined with regex-operator
        set beresp.http.X-URL-CHECK = "url-" + bereq.url;
    
        if (!std.strstr(beresp.http.xkey, beresp.http.X-URL-CHECK)) {
            set beresp.http.xkey += "," + beresp.http.X-URL-CHECK;
        }

    unset beresp.http.X-URL-CHECK;
    }


## The end is here
}
