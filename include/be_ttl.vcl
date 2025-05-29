sub be_ttled {

	### vcl_backens_response
	## This dictates which ones will be cached and how long
	## vcl_hash gave and checked out "only" hash of an object

	## Ordinary default; how long Varnish will keep objects
        # Varnish is using beresp.ttl as s-maxage (max-age is for browser),
	# This is default, and can or will be overdriven later.
	if ( beresp.status == 200 || beresp.ttl > 0s) {
                unset beresp.http.Expires;
		unset beresp.http.Cache-Control;
		unset beresp.http.Pragma;

                #Set how long Varnish will keep it
                set beresp.ttl = 7d;

		# 24h for browsers, 7d for Varnish and beresp.ttl is kind of fallback, if s-maxage is missing
		set beresp.http.Cache-Control = "public, max-age=86400, s-maxage=604800;";

                # Helps to group requests in varnishlog
		set beresp.http.X-Varnish = bereq.xid;
	}	

	## Do not let a browser cache WordPress admin. Safari is very aggressive to cache things
	if (bereq.url ~ "^/wp-(login|admin|my-account|comments-post.php|cron)" || bereq.url ~ "/(login|lataus)" || bereq.url ~ "preview=true") {
		unset beresp.http.Cache-Control;
		set beresp.http.Cache-Control = "no-store, no-cache, must-revalidate, max-age=0";
		set beresp.ttl = 0s;
		return(deliver);
	}

	## Set hit-for-pass for two minutes if TTL is 0 and response headers
  	## allow for validation. 
	# Basically we are caching 304 and giving opportunity to not fetch an uncacheable object,
	# if verification is allowed and use user's or intermediate cache.
	# As is it will cache WordPress admin too? Commented until I'm sure this can be done
	#if (beresp.ttl <= 0s && (beresp.http.ETag || beresp.http.Last-Modified)) {
	#	return(pass(120s));
	#}

        ## Cache some responses only short period
        # Can I do beresp.status == 302 || beresp.status == 307 ?
        if (beresp.status == 404) {
                unset beresp.http.Cache-Control;
		set beresp.http.Cache-Control = "public, max-age=120";
                set beresp.ttl = 120s;
        }

	## 301 and 410 are quite steady, again, so let Varnish cache resuls from backend
	# The idea here must be that first try doesn't go in cache, so let's do another round
       if (beresp.status == 301 && beresp.http.location ~ "^https?://[^/]+/") {
              set bereq.http.host = regsuball(beresp.http.location, "^https?://([^/]+)/.*", "\1");
              set bereq.url = regsuball(beresp.http.location, "^https?://([^/]+)", "");
              return(retry);
      }

        if (beresp.status == 410 && beresp.http.location ~ "^https?://[^/]+/") {
               set bereq.http.host = regsuball(beresp.http.location, "^https?://([^/]+)/.*", "\1");
               set bereq.url = regsuball(beresp.http.location, "^https?://([^/]+)", "");
               return(retry);
        }

	## 301/410 are quite static, so let's change TTL
        if (beresp.status == 301 || beresp.status == 410) {
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 1y;
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
        # so 24h delay is acceptable
        if (bereq.http.Content-Type ~ "^(application|text)/xml") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 1d;
        }

	# Fonts don't change
        if (bereq.http.Content-Type ~ "^font/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=31536000"; # 1y
                set beresp.ttl = 1y;
        }

        # Images don't change
        if (bereq.http.Content-Type ~ "^image/") {
                unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 30d;
        }

	# Large static files are delivered directly to the end-user without waiting for Varnish to fully read t>
        # Most of these should be in CDN, but I have some MP3s behind backend
        # Is this really needed anymore? AFAIK Varnish should do this automatic.
        if (beresp.http.Content-Type ~ "^(video|audio)/") {
		unset beresp.http.Cache-Control;
		unset beresp.http.set-cookie;
		set beresp.http.Cache-Control = "public, max-age=7200"; # 2h for users too, do not eat theirs memory
                set beresp.ttl = 2h; # longer TTL just eats RAM
                set beresp.do_stream = true;
        }


	# These can be really big and not so often requested. And if there is a rush, those can be fetched
        if (bereq.url ~ "^[^?]*\.(7z|bz2|doc|docx|eot|gz|otf|pdf|ppt|pptx|tar|tbz|tgz|txz|xls|xlsx)") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.http.Cache-Control = "public, max-age=604800"; # 1 week
                set beresp.ttl = 12h; # users may need longer than is requested from cache
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
        # Against all claims bots check robots.txt almost never, so caching doesn't help much
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
	# At the moment I'm publishing a lot and fast, so this will stay commented now.
#        if (bereq.url ~ "sitemap") {
#                unset beresp.http.cache-control;
#                set beresp.ttl = 86400s;  # 24h
#        }

        ## Tags this should be same than TTL of feeds. Let's use defaults, though.
        if (bereq.url ~ "tag") {
		unset beresp.http.set-cookie;
        }

        ## Search results, mostly Wordpress if I'm guessing right
        # Normally those querys should pass but I want to cache answers shortly
        # Caching or not doesn't matter because users don't search too often anyway
        if (bereq.url ~ "/\?s=" || bereq.url ~ "/search/") {
		unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=120";
                set beresp.ttl = 5m;
        }
		
	## Some admin-ajax.php calls can be cached by Varnish
	# Except... it is almost always POST or OPTIONS and those are uncacheable
	# This might be an issue, so is commented until I'm sure this can be done
	#if (bereq.url ~ "admin-ajax.php" && bereq.http.cookie !~ "wordpress_logged_in" ) {
	#	unset beresp.http.set-cookie;
	#	set beresp.ttl = 1d;
	#	set beresp.grace = 1d;
	#}

}
