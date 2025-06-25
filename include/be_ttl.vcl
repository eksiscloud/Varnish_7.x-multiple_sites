sub be_ttled {

	### vcl_backend_response
	## This dictates which ones will be cached and how long

	## Ordinary default; how long Varnish will keep objects
        # Varnish is using beresp.ttl as s-maxage (max-age is for browser),
	# This is default, and can or will be overdriven later.
	if ( beresp.status == 200 || beresp.ttl > 0s) {
                unset beresp.http.Expires;
		unset beresp.http.Cache-Control;
		unset beresp.http.Pragma;

                # Set how long Varnish will keep it
		# Varnish will keep cache very long time. Most of content never changes.
		# there will be systen reboot, Varnish restarts and cache warmer and all those changes and refreshes
		# the actual cache no matter this setting
                set beresp.ttl = 52w;

		# 24h for browsers, 365d for Varnish and beresp.ttl is kind of fallback, if s-maxage is missing
		set beresp.http.Cache-Control = "public, max-age=86400, s-maxage=31536000;";

                # Helps to group requests in varnishlog
		set beresp.http.X-Varnish = bereq.xid;
	}	

	## Do not let a browser cache WordPress admin. Safari is very aggressive to cache things
	if (bereq.url ~ 
		"^/wp-(login|admin|my-account|comments-post.php|cron)" || 
		bereq.url ~ "/(login|lataus)" || 
		bereq.url ~ "preview=true") {
			unset beresp.http.Cache-Control;
			set beresp.http.Cache-Control = "no-store, no-cache, must-revalidate, max-age=0";
			set beresp.ttl = 0s;
			return(deliver);
	}
	
	## Conditional 410 for url that may do come back
	call conditional410;

        ## Cache for not found, only short period
        if (beresp.status == 404) {
                unset beresp.http.Cache-Control;
		set beresp.http.Cache-Control = "public, max-age=120";
                set beresp.ttl = 120s;
        }

	## 301 and 410 are quite steady, again, so let Varnish cache results from backend
	# The idea here must be that first try doesn't go in cache, so let's do another round 
	# and cache it using default values
       if (beresp.status == 301 && beresp.http.location ~ "^https?://[^/]+/") {
		if (bereq.retries == 0) {
			set bereq.http.host = regsuball(beresp.http.location, "^https?://([^/]+)/.*", "\1");
			set bereq.url = regsuball(beresp.http.location, "^https?://([^/]+)", "");
			return(retry);
		}
	}

	if (beresp.status == 410) {
		unset beresp.http.Set-Cookie;
		unset beresp.http.Cache-Control;
		# Must set, because default is only for 200
		set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
		set beresp.ttl = 52w;
	}

	## Caching static files improves cache ratio, but eats RAM and doesn't make your site faster per se. 
        # Most of media files should be served from CDN anyway, so let's do some cosmetic caching.

	# This includes .css and .js too.
	# I'll later finetune this by type and actual files
	if (bereq.http.Content-Type ~ "^text/") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
		set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 30d;
	}

	# RSS and other feeds like podcast can be cached
        # Podcast services are checking feed way too often, and I'm quite lazy to publish,
        # so 24h delay is acceptable. And only bots read these.
        if (bereq.http.Content-Type ~ "^(application|text)/xml") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 1d;
        }

	# Fonts don't change, is needed everywhere and are small
        if (bereq.http.Content-Type ~ "^font/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=2592000"; # 1 month
                set beresp.ttl = 1d;
                unset beresp.http.set-cookie;
        }

        # Images don't change but takes space from users' devices
        if (bereq.http.Content-Type ~ "^image/") {
                unset beresp.http.set-cookie;
        }

	# Large static files are delivered directly to the end-user without waiting for Varnish to fully read
        # Most of these should be in CDN, but I have some MP3s behind backend
        # Is this really needed anymore? AFAIK Varnish should do this automatic.
        if (beresp.http.Content-Type ~ "^(video|audio)/") {
		unset beresp.http.Cache-Control;
		unset beresp.http.set-cookie;
		set beresp.http.Cache-Control = "public, max-age=7200"; # 2h for users, do not eat theirs memory
                set beresp.ttl = 2d; # longer TTL just eats RAM
                set beresp.do_stream = true;
        }


	# These can be really big and not so often requested. And if there is a rush, those can be fetched
        if (bereq.url ~ "^[^?]*\.(7z|bz2|doc|docx|eot|gz|otf|pdf|ppt|pptx|tar|tbz|tgz|txz|xls|xlsx)") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=604800"; # 1 week
                set beresp.ttl = 2d; # users may need longer than is requested from cache
                set beresp.do_stream = true;
	}

	## WordPress archive page of podcasts
	if (bereq.url ~ "/podcastit/") {
		unset beresp.http.set-cookie;
		unset beresp.http.cache-control;
		set beresp.http.cache-control = "public, max-age=43200"; # 12h for client
		set beresp.ttl = 2d;
	}

        ## Robots.txt is really static, but let's be on safe side
        # Against all claims bots check or follow robots.txt almost never, so caching doesn't help much
        if (bereq.url ~ "/robots.txt") {
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=604800";
                set beresp.ttl = 30d;
        }

        ## ads.txt and sellers.json is really static to me, but let's be on safe side
        if (bereq.url ~ "^/(ads.txt|sellers.json)") {
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=604800";
                set beresp.ttl = 30d;
        }

	## Sitemaps should be rally'ish dynamic, but are those? But this is for bots only.
        if (bereq.url ~ "sitemap") {
                unset beresp.http.cache-control;
		set beresp.http.Cache-Control = "public, max-age=604800"; # useless, only bots read this
                set beresp.ttl = 24h;
        }

        ## Tags, this should be same than TTL of feeds.
        if (bereq.url ~ "/tag") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 1d;
        }

        ## Search results, mostly Wordpress
        # Normally those querys should pass but I want to cache answers shortly
        # Caching or not doesn't matter because users don't search too often anyway
        if (bereq.url ~ "/\?s=" || bereq.url ~ "/search/") {
		unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=120";
                set beresp.ttl = 5m;
        }
		

}
