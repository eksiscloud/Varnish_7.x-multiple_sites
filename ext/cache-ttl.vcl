##
sub time_to_go {

	### Global defaults

	## Ordinary default; how long Varnish will keep objects
        # Varnish is using beresp.ttl as s-maxage (max-age is for browser),
        #
	# Server must reboot about once in month so let's use it
        # Backend may want something different, but we don't care
        # Heads up! What should I do with nonce by Wordpress? That can't be cached over 12 hours says all docs.
        #
	# This I used earlier
	#if (beresp.http.cache-control !~ "s-maxage") {
	#	set beresp.ttl = 30d;
	#} else {
		# or if you will pass TTL to other intermediate caches as CDN, otherwise they will use maxage
	#	set beresp.http.cache-control = "s-maxage=31536000, " + beresp.http.cache-control;
	#}
	#
	# This I use now
	# I make Varnish cache time x, but I'll tell to user caching very shorter time, because they re-visit quote rarely, and
	# I force them download fresh content
	# This is default, and can or will be overdriven later.
	if ( beresp.status == 200 || beresp.ttl > 0s) {
                unset beresp.http.expires;
		unset beresp.http.cache-control;

                # Set the clients TTL on this object
                set beresp.http.cache-control = "max-age=86400"; # 24h

                #Set how long Varnish will keep it
                set beresp.ttl = 7d;

                # I don't know why I'm doing this
		set beresp.http.X-Varnish = bereq.xid;
	}	

	## Set hit-for-pass for two minutes if TTL is 0 and response headers
  	## allow for validation. 
	# Basically we are caching 304 and giving opportunity to not fetch an uncacheable object,
	# if verification is allowed and use user's or intermediate cache.
	if (beresp.ttl <= 0s && (beresp.http.ETag || beresp.http.Last-Modified)) {
		return(pass(120s));
	}

        ## Cache some responses only short period
        # Can I do beresp.status == 302 || beresp.status == 307 ?
        if (beresp.status == 404) {
                unset beresp.http.cache-control;
		set beresp.http.cache-control = "max-age=300";
                set beresp.ttl = 1h;
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
                unset beresp.http.cache-control;
                set beresp.http.cache-control = "max-age=86400"; # 24h
                set beresp.ttl = 1y;
        }

	## Caching static files improves cache ratio, but eats RAM and doesn't make your site faster per se. 
        # Most of media files should be served from CDN anyway, so let's do some cosmetic caching.

        # .css and .js are relatively long lasting; this can be an issue after updating, though
        if (beresp.http.Content-Type ~ "^text/(css|javascript)") {
		# This I did earlier...
	#        if (beresp.http.Cache-Control ~ "(?i:no-cache|no-store|private)") {
        #                unset beresp.http.Cache-Control;
        #                unset beresp.http.set-cookie;
        #        }
        #        set beresp.ttl = 1y;
		# ...but because I set up cache-control in the beginning, all I do now is cleaning cookies
		unset beresp.http.set-cookie;
        }

        # These can be really big and not so often requested. And if there is a rush, those can be fetched
        if (bereq.url ~ "^[^?]*\.(7z|bz2|csv|doc|docx|eot|gz|otf|pdf|ppt|pptx|rtf|tar|tbz|tgz|ttf|txt|txz|xls|xlsx)") {
		unset beresp.http.Cache-Control;
                unset beresp.http.set-cookie;
                set beresp.ttl = 12h;
                set beresp.do_stream = true;
        }

        # Images don't change
        if (beresp.http.Content-Type ~ "^(image)/") {
                # again, earlier this way...
		#if (beresp.http.Cache-Control ~ "(?i:no-cache|no-store|private)") {
                        unset beresp.http.Cache-Control;
                        unset beresp.http.set-cookie;
                #}
                #set beresp.ttl = 600s;
        }

	## Large static files are delivered directly to the end-user without waiting for Varnish to fully read t>
        # Most of these should be in CDN, but I have some MP3s behind backend
        # Is this really needed anymore? AFAIK Varnish should do this automatic.
        if (beresp.http.Content-Type ~ "^(video|audio)/") {
		# I'm cleaning unnecessary if
                #if (beresp.http.Cache-Control ~ "(?i:no-cache|no-store|private)") {
                        unset beresp.http.Cache-Control;
                #}
                set beresp.ttl = 2h; # longer TTL just eats RAM
		unset beresp.http.set-cookie;
                set beresp.do_stream = true;
        }

        ### Per site

	## RSS and other feeds like podcast can be cached
        # Podcast services are checking feed way too often, and I'm quite lazy to publish,
	# so 24h delay is acceptable
        if (beresp.http.Content-Type ~ "text/xml") {
		#if (beresp.http.Cache-Control ~ "(?i:no-cache|no-store|private)") {
			unset beresp.http.Cache-Control;
		#}
		#set beresp.http.cache-control = "max-age=86400"; # 24h
                set beresp.ttl = 86400s;
        }

        ## Robots.txt is really static, but let's be on safe side
        # Against all claims bots check robots.txt almost never, so caching doesn't help much
        if (bereq.url ~ "/robots.txt") {
                unset beresp.http.cache-control;
                set beresp.http.cache-control = "max-age=604800";
                set beresp.ttl = 30d;
        }

        ## ads.txt and sellers.json is really static to me, but let's be on safe side
        if (bereq.url ~ "^/(ads.txt|sellers.json)") {
                unset beresp.http.cache-control;
                set beresp.http.cache-control = "max-age=604800";
                set beresp.ttl = 30d;
        }

	## Sitemaps should be rally'ish dynamic, but are those? But this is for bots only.
        if (bereq.url ~ "sitemap") {
                unset beresp.http.cache-control;
                #set beresp.http.cache-control = "max-age=120";
                set beresp.ttl = 1h;
        }

        ## Tags this should be same than TTL of feeds. I don't have.
        if (bereq.url ~ "(avainsana|tag)") {
                unset beresp.http.cache-control;
                #set beresp.http.cache-control = "max-age=86400"; # 24h
                set beresp.ttl = 24h;
        }

        ## Search results, mostly Wordpress if I'm guessing right
        # Normally those querys should pass but I want to cache answers shortly
        # Caching or not doesn't matter because users don't search too often anyway
        if (bereq.url ~ "/\?s=" || bereq.url ~ "/search/") {
                unset beresp.http.cache-control;
                #set beresp.http.cache-control = "max-age=120";
                set beresp.ttl = 5m;
        }

	## Let's go to site-level
	if (bereq.http.host ~ "www.(katiska|eksis)|jagster.|dev.|store.") {
		
		## I have an issue with one cache-control value from WordPress when speedtesting
		if (bereq.url ~ "/icons.ttf\?pozjks") {
			unset beresp.http.set-cookie;
			set beresp.http.cache-control = "max-age=31536000";
		}

		## WordPress archive page of podcasts
		if (bereq.url ~ "/podcastit/") {
			unset beresp.http.cache-control;
			set beresp.http.cache-control = "max-age=43200"; # 12h for client
			set beresp.ttl = 2d;
		}
		
		## Some admin-ajax.php calls can be cached by Varnish
		# Except... it is almost always POST or OPTIONS and those are uncacheable
		if (bereq.url ~ "admin-ajax.php" && bereq.http.cookie !~ "wordpress_logged_in" ) {
			unset beresp.http.set-cookie;
			set beresp.ttl = 1d;
			set beresp.grace = 1d;
		}
	}

        ## My repo/Gitea
	#if (bereq.http.host ~ "git.eksis.one") {
        
		# Heads up: this caching is a bit too much
	#	if (bereq.url ~ "/src/" || bereq.url ~ "/explore/" ) {
			#unset beresp.http.set-cookie;
	#		set beresp.ttl = 1d;
	#		set beresp.grace = 1d;
	#		set beresp.http.cache-control = "max-age=86400"; # 24h
	#	}
	#}

	## Moodle and static objects
	# I don't use Moodle anymore so another example
        #if (bereq.http.host ~ "pro.(katiska|eksis)") {
	#	if (
	#	beresp.http.Cache-Control &&
	#	bereq.http.x-moodle-ttl &&
	#	beresp.ttl < std.duration(bereq.http.x-moodle-ttl + "s", 1s) &&
	#	!beresp.http.WWW-Authenticate
        #        ) {
			# If max-age < defined in x-moodle-ttl header
	#		set beresp.http.X-Orig-Cache-Control = beresp.http.Cache-Control;
	#		set beresp.http.Cache-Control = "public, max-age="+bereq.http.X-Long-TTL + ", no-transform";
	#		set beresp.ttl = std.duration(bereq.http.x-moodle-cache + "s", 1s);
	#		unset bereq.http.x-moodle-cache;
	#	}

	#	elseif (
        #        !beresp.http.Cache-Control &&
        #        bereq.http.x-moodle-ttl &&
        #        !beresp.http.WWW-Authenticate
        #        ) {
	#		set beresp.http.Cache-Control = "public, max-age="+bereq.http.x-moodle-ttl + ", no-transform";
	#		set beresp.ttl = std.duration(bereq.http.x-moodle-ttl + "s", 1s);
	#		unset bereq.http.x-moodle-ttl;
	#	} else { 
			# Don't touch headers if max-age > defined in x-moodle-ttl header
	#		unset bereq.http.x-moodle-ttl;
	#	}

	#}
## The ending
}
