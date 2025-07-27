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

		# 24h for browsers, 365d for Varnish using beresp.ttl as a fallback. s-maxage is for other intermediate caches.
		# This hits in if there is no cache-control in use
		set beresp.http.Cache-Control = "public, max-age=86400, s-maxage=31536000;";

                # Helps to group requests in varnishlog
		set beresp.http.X-Varnish = bereq.xid;
	}	

	## Do not let a browser cache WordPress admin. Safari is very aggressive to cache things
	if (bereq.url ~ 
		"^/wp-(login|admin|my-account|comments-post.php|cron)" || 
		bereq.url ~ "/login" || 
		bereq.url ~ "preview=true") {
			unset beresp.http.Cache-Control;
			set beresp.http.Cache-Control = "no-store, no-cache, must-revalidate, max-age=0";
			set beresp.ttl = 0s;
			return(deliver);
	}
	
	## Conditional 410 for url that may do come back
	call conditional410;

	## 301 and 410 are quite steady, so let Varnish cache results from backend
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

	### Caching static files improves cache ratio, but eats RAM and doesn't make your site faster per se. 

	## First I deal with content types, kind of semi-defaults

        # Fonts don't change, is needed everywhere and are small
        if (beresp.http.Content-Type ~ "^font/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=2592000"; # 1 month
                set beresp.ttl = 52w;
        }

        # Images don't change but takes space from users' devices
        if (beresp.http.Content-Type ~ "^image/") {
                unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=172800s"; # 2d
                set beresp.ttl = 52w;
        }

       # Large static files are delivered directly to the end-user without waiting for Varnish to fully read
        # Most of these should be in CDN, but I have some MP3s behind backend
        # Is this really needed anymore? AFAIK Varnish should do this automatic.
        # I shouldn't have any local videos, though
        if (beresp.http.Content-Type ~ "^(video/)") {
                unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.uncacheable = true;
                set beresp.ttl = 0s;
                set beresp.do_stream = true;
                # for clarity and logging
                set beresp.http.X-Cache-Control = "pass: streamed video";
        }
        # this is for local audio only, if any
        if (beresp.http.Content-Type ~ "^(audio)/") {
                unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=7200s"; # 2h
                set beresp.ttl = 24h;
                set beresp.do_stream = true;
	}

	# This include CSS and JS too, but those are dealed later, though
        if (beresp.http.Content-Type ~ "^text/" || beresp.http.Content-Type ~ "application/(json|xml)") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=1209600"; # 2w
                set beresp.ttl = 30d;
        }

	## Second: static files will overdrive content type, if there is a match

	# CSS/JS may change when updating. But WordPress will purge cache when updated, so mainly I'm taking care users here.
	if (bereq.url ~ "\.(css|js)") {
		unset beresp.http.set-cookie;
		unset beresp.http.Cache-Control;
		set beresp.http.Cache-Control = "public, max-age=1209600"; # 2w client
		set beresp.ttl = 52w;
	}

        # These can be really big and not so often requested. And if there is a rush, those can be fetched
        if (bereq.url ~ "^[^?]*\.(7z|bz2|doc|docx|eot|gz|otf|pdf|ppt|pptx|tar|tbz|tgz|txz|xls|xlsx)") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=604800"; # 1 week
                set beresp.ttl = 4w; # users may actually need longer than is requested from cache
                set beresp.do_stream = true;
        }

	## Lastly there is paths, urls and direct files. Again: this section overdrives earlie ruoe, if there is a match

        # Podcast-feeds
        if (bereq.url ~ "^/feed/podcast/[^/]+/?$") {
		unset beresp.http.Cache-Control;
		unset beresp.http.set-cookie;
		set beresp.http.Cache-Control = "public, max-age=86400"; # 24h, what is the point for this...
		set beresp.ttl = 1w; # could be longer with xkey?
	}

        # WordPress article/RSS-feeds (legacy stuff, not in use)
        if (bereq.url ~ "^/.+/.+/feed/?$") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h, what is the point for this...
                set beresp.ttl = 52w;
	}

        ## Mastodon/ActivityPub aren't active
        if (bereq.url ~ "^/wp-json/activitypub/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h, what is the point for this...
                set beresp.ttl = 1w;
        }
        if (bereq.url ~ "^/api/(v1|v2)/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h, what is the point for this...
                set beresp.ttl = 1w;
        }
        if (bereq.url ~ "^/(nodeinfo|webfinger)") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h, what is the point for this...
                set beresp.ttl = 4w;
        }

	# WordPress archive page of podcasts
	if (bereq.url ~ "^/podcastit(/)?$") {
		unset beresp.http.set-cookie;
		unset beresp.http.cache-control;
		set beresp.http.cache-control = "public, max-age=43200"; # 12h for client
		set beresp.ttl = 52w; # xkey will purge this
	}

        # Robots.txt is really static, but let's be on safe side
        # Against all claims bots check or follow robots.txt almost never, so caching doesn't help much
        if (bereq.url ~ "/robots.txt") {
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=604800";
                set beresp.ttl = 30d;
        }

        # ads.txt and sellers.json is really static to me, but let's be on safe side
        if (bereq.url ~ "^/(ads.txt|sellers.json)") {
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=604800";
                set beresp.ttl = 30d;
        }

	# Sitemaps should be rally'ish dynamic, but are those? But this is for bots only.
        if (bereq.url ~ "sitemap") {
                unset beresp.http.cache-control;
		set beresp.http.Cache-Control = "public, max-age=604800"; # useless, only bots read this
                set beresp.ttl = 24h;
        }

        ## Tags, this should be same than TTL of archives. This is controlled by xkey, though
        if (bereq.url ~ "/tag") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 4w;
        }

        ## I'm trying to understand why some images get low TTL
        # log ttl of the most used images. Here we can log only misses, because hits never arrived here
        if (bereq.url ~ "(?i)\.(jpeg|jpg|png|webp)(\?.*)?$" && beresp.ttl < 52w) {
                # from the backend, aka. miss
                std.log("IMAGE_TTL_BACKEND: " + bereq.url + " TTL=" + beresp.ttl);
		std.syslog(150, "IMAGE_TTL_BACKEND: " + bereq.url + " TTL=" + beresp.ttl); 
        }

## End of this one
}
