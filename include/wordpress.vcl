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
        if (req.http.X-Bypass-Cache == "1" && req.http.User-Agent == "CacheWarmer") {
                return(pass);
        }	

	## Enable smart refreshing, aka. ctrl+F5 will flush that page
        # Remember your header Cache-Control must be set something else than no-cache
        # Otherwise everything will miss
        if (req.http.Cache-Control ~ "no-cache" && req.http.X-Bypass != "true") {
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

        ## Must Use plugins I reckon
        if (req.url ~ "/mu-.*") {
                return(pass);
        }
		
	## Adsense incomings are lower when Varnish is on, trying to solve out this
	# is it because of caching or CSP-rules?
	if (req.url ~ "adsbygoogle") {
		return(pass);
	}

        ## REST API 
        # I don't want to fill RAM for benefits of bots.
        
        # Mastodon/ActivityPub
        if (req.url ~ "^/wp-json/(activitypub|friends)/") {
                return(pass);
        }
	if (req.url ~ "^/api/(v1|v2)/") {
		return(pass);
	}
	if (req.url ~ "^/(nodeinfo|webfinger)") {
		return(pass);
	}
	
	# .well-known API route should not be cached
        if (req.url ~ "^/.well-known/") {
                return(pass);
        }

        # WordPress REST API
	if (req.url ~ "/wp-json/wp/") {
		if (req.http.Cookie ~ "wordpress_logged_in") {
			return(pass);
		}
		return(synth(403, "Unauthorized request"));
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

	# Text-files are static, so cache it is.
	# Cache these is equally stupid than caching images, though.
	# This includes sitemaps, so consider smart TTL and remember: the order matters
        if (req.http.Content-Type ~ "text/") {
                unset req.http.cookie;
                return(hash);
        }

	# Fonts, another useless caching strategy
        if (req.http.Content-Type ~ "font/") {
                unset req.http.cookie;
                return(hash);
        }

	# Feeds should be cached, but on other side: only bots use them
        if (req.http.Content-Type ~ "(application|text)/xml") {
                unset req.http.cookie;
                return(hash);
	}

	# JavaScript are operating in user's device, so caching them is no issue. 
	# But those don't create no load in backend, and need BAN after updates.
	# Do you even know when Google Ads does updates?
        if (req.http.Content-Type ~ "(text|application)/javascript") {
                unset req.http.cookie;
                return(hash);
	}
	
	# Large static audio files will be cached and streamed. I don't host videos, so those are just extra.
        # The job will be done at vcl_backend_response
        # But is this really needed nowadays?
        if (req.http.Content-Type ~ "(audio|video)/") {
                unset req.http.cookie;
                return(hash);
        }

	# Let's cache images, even it is a stupid move
	if (req.http.Content-Type ~ "image/") {
		unset req.http.cookie;
		return(hash);
	}

       ## Cache all static files by Removing all Cookies for static files
        # These haven't Content-type, I don't know it or there is another reason to keep this that way.
        # Remember, do you really need to cache static files that don't cause load? Only if you have memory left.
        if (req.url ~ "^[^?]*\.(7z|bz2|doc|docx|eot|gz|otf|pdf|ppt|pptx|tar|tbz|tgz|xls|xlsx|xz|zip)(\?.*)?$") {
                unset req.http.cookie;
                return(hash);
        }
	
	## Hit everything else
        if (req.url !~ "(wp-(login.php|cron.php|admin|comment)|login|my-account|addons|loggedout|lost-password)") {
                unset req.http.cookie;
        }

	## Normalize the query arguments.
        # Perhaps wp-admin etc should be excluded?
        # If std.querysort is any earlier it will break things, like giving error 500 when logging out.
	# Every other VCL examples use this really early, but those are really aged tips and 
	# I'm not so sure if those are actually ever tested in production.
	set req.url = std.querysort(req.url);

}
