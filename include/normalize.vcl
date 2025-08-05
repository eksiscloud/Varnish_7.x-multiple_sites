sub normalize {

	## Redirecting http/80 to https/443
        # This could, and will, happen in Nginx, so this is just a safenet
        if ((req.http.X-Forwarded-Proto && req.http.X-Forwarded-Proto != "https") ||
        (req.http.Scheme && req.http.Scheme != "https")) {
                return(synth(750));
        }

        ## It will terminate badly formed requests
        ## Build-in rule. But works only if there isn't return(...) that forces jump away
        if (!req.http.host && req.esi_level == 0 && req.proto ~ "^(?i)HTTP/1.1") {
                # In HTTP/1.1, Host is required. Hostless ones are stopped by Nginx, though.
                return(synth(400));
        }

        ## Normalize the header, remove the port (in case you're testing this on various TCP ports)
        set req.http.host = std.tolower(req.http.host);
        set req.http.host = regsub(req.http.host, ":[0-9]+", "");

	## I don`t like capitalized ones
	set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);

	## Quite often russian lie used IP but keep russian as a language
	if (req.http.Accept-Language ~ "^ru" &&
	    req.http.Accept-Language !~ "(?i)fi|en|sv") { 
		set req.http.X-Match = "only-russian-language";
		return(synth(403, "Blocked: Russian-only Accept-Language"));
	}

        ## Setting http headers for backend
        if (req.restarts == 0) {
                if (req.http.X-Forwarded-For) {
                        set req.http.X-Forwarded-For =
                        req.http.X-Forwarded-For + " " + req.http.X-Real-IP;
                } else {
                        set req.http.X-Forwarded-For = req.http.X-Real-IP;
                }
        }

        ## Let's tune up a bit behavior for healthy backends: I use long TTLs and snapshot-backend
        if (std.healthy(req.backend_hint)) {
                set req.grace = 30s;
        }

	## X-Bypass-Cache needs...
	# acl
	if (req.http.X-Bypass != "true" && req.http.X-Bypass-Cache) {
		unset req.http.X-Bypass-Cache;
	}
	# Out there is two variants, true and 1
	elseif (req.http.X-Bypass-Cache == "true") {
		set req.http.X-Bypass-Cache = "1";
	}
        
        ## Only deal with "normal" types
        # In-build rules. Those aren't needed, unless return(...) forces skip it.
        # Heads up! BAN/PURGE/REFRESH must be done before this or declared here. Unless those don't work when purging or banning.
        # Heads up! If you are filtering methods in Nginx/Apache2 allow same ones there too
        if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PATCH" &&
        req.method != "DELETE" &&
        req.method != "PURGE" &&
	req.method != "BAN"
        ) {
        # Non-RFC2616 or CONNECT which is weird.
        # Why send the packet upstream, while the visitor is using a non-valid HTTP method?
                return(synth(405, "Non-valid HTTP method!"));
        }

	## Remove known following parameters, useless for backend
	# Analytics: utm_*, gclid, fbclid, msclkid, ga_source
	# Marketing: mc_cid, mc_eid, trk, elqTrackId
	# Social: fb_source, shared, msg, ref, igshid
	# WordPress related: tmstv, siteurl, cx, cof, ie
	# Hubspot: _hsenc, _hsmi
	set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|msclkid|dclid|yclid|mc_cid|mc_eid|cx|ie|cof|siteurl|ref|igshid|fb_source|trk|elqTrackId|tmstv|shared|msg|_hsenc|_hsmi|ga_source)=[^&]*", "");
	set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|msclkid|dclid|yclid|mc_cid|mc_eid|cx|ie|cof|siteurl|ref|igshid|fb_source|trk|elqTrackId|tmstv|shared|msg|_hsenc|_hsmi|ga_source)=[^&]*", "?");
	set req.url = regsub(req.url, "\?&", "?");
	set req.url = regsub(req.url, "\?$", "");

        ## Save Origin (for CORS) in a custom header and remove Origin from the request 
        ## so that backend doesn’t add CORS headers.
        set req.http.X-Saved-Origin = req.http.Origin;
        unset req.http.Origin;

        ## Some devices, mainly from Apple, send urls ending /null
        if (req.url ~ "/null$") {
                set req.url = regsub(req.url, "/null", "/");
        }

# The sub stops here
}

