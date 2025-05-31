sub set_normalizing {

        ## It will terminate badly formed requests
        ## Build-in rule. But works only if there isn't return(...) that forces jump away
        if (!req.http.host && req.esi_level == 0 && req.proto ~ "^(?i)HTTP/1.1") {
                # In HTTP/1.1, Host is required.
                return (synth(400));
        }

        ## if there is PROXY in use
        # Used with Hitch or similar dumb ones 
        #elseif (!req.http.X-Forwarded-Proto && !req.http.Scheme && !proxy.is_ssl()) {
        #       return(synth(750));
        #}
        
        ## Let's clean up Proxy.
        # It comes from dumb TSL-proxies like Hitch
        # This is old security measurement too
        unset req.http.Proxy;

        ## Normalize the header, remove the port (in case you're testing this on various TCP ports)
        set req.http.host = std.tolower(req.http.host);
        set req.http.host = regsub(req.http.host, ":[0-9]+", "");

	## I don`t like capitalized ones
	set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);

        # Quite often russians lie origin country, but are declaring russian as language
        if (req.http.Accept-Language ~
                "(ru)"
        ) {
                std.log("banned language: " + req.http.Accept-Language);
                return(synth(403, "Unsupported language: " + req.http.Accept-Language));
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

        ## Let's tune up a bit behavior for healthy backends: Cap grace to 12 hours
        if (std.healthy(req.backend_hint)) {
                set req.grace = 43200s;
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
        req.method != "PURGE"
        ) {
        # Non-RFC2616 or CONNECT which is weird.
        # Why send the packet upstream, while the visitor is using a non-valid HTTP method?
                return(synth(405, "Non-valid HTTP method!"));
        }

        ## Normalizing language
        # Everybody will get fi. Should I remove it totally?
        #set req.http.Accept-Language = lang.filter(req.http.Accept-Language);

	## Remove the Google Analytics added parameters, useless for backend
	if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=") {
		set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
		set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
		set req.url = regsub(req.url, "\?&", "?");
		set req.url = regsub(req.url, "\?$", "");
	}

        ## Save Origin (for CORS) in a custom header and remove Origin from the request 
        ## so that backend doesn’t add CORS headers.
        set req.http.X-Saved-Origin = req.http.Origin;
        unset req.http.Origin;

        ## Send Surrogate-Capability headers to announce ESI support to backend
        # I don't understand at all what this is doing
        #set req.http.Surrogate-Capability = "key=ESI/1.0";

        ## Some devices, mainly from Apple, send urls ending /null
        if (req.url ~ "/null$") {
                set req.url = regsub(req.url, "/null", "/");
        }

}

