sub wp {

        ## Implementing websocket support
        if (req.http.Upgrade ~ "(?i)websocket") {
                return(pipe);
        }

	## Only GET and HEAD are cacheable methods AFAIK
        # In-build rule too
        if (req.method != "GET" && req.method != "HEAD") {
                return(pass);
        }

        ## Cache warmup
        # wget --spider -o wget.log -e robots=off -r -l 5 -p -S -T3 --header="X-Bypass-Cache: 1" --header="User-Agent:CacheWarmer">
        # It saves a lot of directories, so think where you are before launching it... A protip: /tmp
        if (req.http.X-Bypass-Cache == "1") {
                return(pass);
        }	

	## Enable smart refreshing, aka. ctrl+F5 will flush that page
        # Remember your header Cache-Control must be set something else than no-cache
        # Otherwise everything will miss
        if (req.http.Cache-Control ~ "no-cache" && req.http.X-Bypass != "1" && req.http.Cookie) {
                set req.hash_always_miss = true;
        }

	## Do not cache AJAX requests.
	if (req.http.X-Requested-With == "XMLHttpRequest") {
		return(pass);
	}

        ## Don't cache wordpress related pages
        if (req.url ~ "(signup|activate|mail|logout)") {
                return(pass);
        }

	## Adsense incomings are lower when Varnish is on, trying to solve out this
	# is it because of caching or CSP-rules?
	if (req.url ~ "adsbygoogle") {
		return(pass);
	}
        
	# .well-known API route should not be cached
        if (req.url ~ "^/.well-known/") {
                return(pass);
        }

        ## WordPress REST API
	if (req.url ~ "^/wp-json/wp/") {
            if (req.http.Authorization) {
                return (pass);
            }
            if (req.http.Cookie ~ "wordpress_logged_in") {
                return (pass);
            }
            return (synth(403, "Unauthorized request"));
	}

	## Normalize the query arguments.
        # I'm excluding admin, because otherwise it will cause issues.
        # If std.querysort is any earlier it will break things, like giving error 500 when logging out.
        # Every other VCL examples use this really early, but those are really aged tips and 
        # I'm not so sure if those are actually ever tested in production.
	# Done after all passes and before the first hash.
	if (req.url !~ "^/wp-(admin|login)" && req.url !~ "/logout") {
		set req.url = std.querysort(req.url);
	}

	
	## Remove query strings from some static files
	if (req.url ~ "\.(?:png|jpg|jpeg|webp|gif|css|js|woff2?)\?.*") {
		set req.url = regsub(req.url, "\?.*", "");
	}

	## Hit everything else
	# First, bye bye cookies
        if (req.url !~ "(wp-(login.php|cron.php|admin|comment)|login|my-account|addons|loggedout|lost-password)") {
                unset req.http.cookie;
        }
	# Second, welcome hash
	return(hash); # Varnish will do this anyway and actually this will break in-build VCL, but the next stop is hash, so...

## The end is here
}
