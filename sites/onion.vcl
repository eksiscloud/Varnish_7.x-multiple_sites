# Jakke Lehtonen
##
## First version for testing, if this is possible at all.
## That's why this version is for one host only.
## 
## * * * * *
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.7.1 default.vcl/onion.vcl for onion mirror for tor use.
## 
## onion.vcl, same as default.vcl, is splitted in few sub vcls. Those use includes.  
## That make updating much more easier, because most of my hosts are WordPresses.
##
## This works as a standalone VCL for one WordPress host too
##  
## Lets's start caching (...and a little bit more)

########

# Marker to tell the VCL compiler that this VCL has been adapted to the 4.1 format.
vcl 4.1;

# native ones
import std;             # Load the std, not STD for god sake

backend onion {
        .host = "127.0.0.1";
        .port = "8282";
	.max_connections = 5000;
        .first_byte_timeout = 300s;
        .connect_timeout = 300s;
        .between_bytes_timeout = 300s;
}

#################### vcl_init ##################
## Called when VCL is loaded, before any requests pass through it. Typically used to initialize VMODs.
## You have to define server at backend definition too.

sub vcl_init {
        
# The end of init
}


################### vcl_recv ##################
## We should have here only statments without return(...) or is must be unconditionally and stop process
## The solution has explained here: https://www.getpagespeed.com/server-setup/varnish/varnish-virtual-hosts
## Here we are telling to Varnish what to do and what to cache or not. This is not for backend or i.e. browsers.

sub vcl_recv {

	## All normal and we use this backend
	set req.backend_hint = onion;

        ## just for these virtual hosts
        # for stop caching uncomment
        #return(pass);
        # for dumb TCL-proxy uncomment
        #return(pipe);

        ### The work starts here
	
  	## We don't want these from outside (why would anyone do such thing)
	unset req.http.X-Pseudo;
	unset req.http.X-Redirect-Target;

	## This makes filtering little bit easier
	if (req.http.host ~ "^rfuwrkgfnbdb57mdk7p3gvwehcrzewoqojramfhux7fal7l7bhvxzkqd\.onion") {
		set req.http.X-Pseudo = "eksis";
	} else if (req.http.host ~ "^m7exyvudxph6a4ooxyips6ujx6dhyoxa6e5kb7xo76nzrapubndka2id\.onion") {
		set req.http.X-Pseudo = "jagster";
	} else if (req.http.host ~ "^tf4yktl7spk5xdaon67b7zpa3jffzba2g2xu5l3k5ipeg5rdzq2wqhad\.onion") {
		set req.http.X-Pseudo = "katiska";
	} else if (req.http.host ~ "^pdb77kdgubijdocwbizyhi7iawcr3vnwsdiv5kwabua2rgvy2b7py2yd\.onion") {
		set req.http.X-Pseudo = "poochie";
	}

	## To keep everything inside the onion, we need some headers
        set req.http.X-From-Onion = "1";
        set req.http.X-Forwarded-Proto = "http";
        unset req.http.X-Forwarded-For;
        set req.http.X-Forwarded-For = "127.0.0.1";

        ## Short grace, because I'm using long TTLs
	set req.grace = 30s;

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
        # so that backend doesn’t add CORS headers.
        set req.http.X-Saved-Origin = req.http.Origin;
        unset req.http.Origin;

	## Cleaning User-Agent. We really don't want it in the cache
	set req.http.x-agent = req.http.User-Agent;
        unset req.http.User-Agent;

        ## I'm cleaning language. I don't have multilangual sites.
        # For REAL normalizing you should work with Accept-Language only
        # Now I just remove lang.
        unset req.http.Accept-Language;

	## Ban & Purge
	if (req.method == "BAN" || req.method == "PURGE") {
    		# Normal no-go rules
                if (req.http.X-Bypass != "true") {
                        return(synth(405, "Forbidden"));
                }

                if (!req.http.xkey-purge) {
                        return(synth(400, "Missing xkey"));
                }

    		# Use only allowed xkey-tags
                if (req.http.xkey-purge !~ "^frontpage$" &&
                    req.http.xkey-purge !~ "^sidebar$" &&
                    req.http.xkey-purge !~ "^url-.*" &&
                    req.http.xkey-purge !~ "^article-[0-9]+$" &&
                    req.http.xkey-purge !~ "^domain-[a-z0-9-]+$"&&
                    req.http.xkey-purge !~ "^tag-[a-z0-9-]+$" &&
                    req.http.xkey-purge !~ "^category-[a-z0-9-]+$"
                   ) {
                         std.log("Unknown xkey: " + req.http.xkey-purge);
                         return(synth(404, "Unknown xkey tag: " + req.http.xkey-purge));
                }

    		# When BAN happens
                if (req.method == "BAN") {
			std.syslog(150, "BAN_TAG host=" + req.http.host + " tag=" + req.http.xkey-purge);
                        ban("obj.http.xkey ~ " + req.http.xkey-purge);
                        return(synth(200, "Banned: " + req.http.xkey-purge));
                }

    		# Using hard PURGE for xkey-urls
                if (req.method == "PURGE") {
                        if (req.http.xkey-purge && req.http.xkey-purge ~ "^url-") {
                                xkey.purge(req.http.xkey-purge);
                                return(synth(200, "Hard purged: " + req.http.xkey-purge));
                        }
                        if (req.http.xkey-purge && req.http.xkey-purge ~ "^domain-") {
                                xkey.purge(req.http.xkey-purge);
                                return(synth(200, "Hard purged: " + req.http.xkey-purge));
                        }

                        # Soft fallback-purge
                        ban("obj.http.xkey ~ " + req.http.xkey-purge);
                        return(synth(200, "Soft purged: " + req.http.xkey-purge));
                }

                # REFRESH or another PURGE
                return(hash);
	}

	## CORS is needed in the onion world, I reckon
	# Incoming requests
        if (req.http.Origin) {
                std.log("CORS check: incoming request with Origin: " + req.http.Origin + " → URL: " + req.url);

        # Whitelist allowed origins using regular expression
        if (req.http.X-Pseudo) {
                set req.http.X-Saved-Origin = req.http.Origin;
                std.log("CORS accepted: " + req.http.Origin);
        } else {
                std.log("CORS denied: " + req.http.Origin);
                }
        }

	## Only GET, HEAD and static'ish urls may continue
	# Everything else redirect back to the light of the clearnet
	if ( (req.method != "GET" && req.method != "HEAD")
	     || req.url ~ "(?i)^/wp-(login|admin|cron)|login|my-account|signin(/|\\?|$)"  
	     || req.url ~ "^/wp-json/wp/"
	   ) {

		if (req.http.X-Pseudo == "eksis") {
			set req.http.X-Redirect-Target = "https://www.eksis.one" + req.url;
                } else if (req.http.X-Pseudo == "jagster") {
                        set req.http.X-Redirect-Target = "https://jagster.eksis.one" + req.url;
                } else if (req.http.X-Pseudo == "katiska") {
                        set req.http.X-Redirect-Target = "https://www.katiska.eu" + req.url;
                } else if (req.http.X-Pseudo == "poochie") {
                        set req.http.X-Redirect-Target = "https://www.poochierevival.info" + req.url;
                } else {
                        # fallback, should never happen
                        set req.http.X-Redirect-Target = "https://www.eksis.one";
                }
                return (synth(301, "Redirect to clearnet"));
	}

	## Strip a trailing ? if it exists 
	if (req.url ~ "\?$") {
		set req.url = regsub(req.url, "\?$", "");
	}

        ## Implementing websocket support
        if (req.http.Upgrade ~ "(?i)websocket") {
                return(pipe);
        }

        ## Enable smart refreshing, aka. ctrl+F5 will flush that page
        # Remember your header Cache-Control must be set something else than no-cache
        # Otherwise everything will miss
        if (req.http.Cache-Control ~ "no-cache" && req.http.X-Bypass != "1" && req.http.Cookie) {
                set req.hash_always_miss = true;
        }

        ## Cookies are easy. We do not use them here.
        if (req.http.cookie == "") {
                unset req.http.cookie;
        }

        ## .well-known API route should not be cached
        if (req.url ~ "^/.well-known/") {
                return(pass);
        }

	## Normalize query arguments
	set req.url = std.querysort(req.url);

        ## Remove query strings from some static files
        if (req.url ~ "\.(?:png|jpg|jpeg|webp|gif|css|js|woff2?)\?.*") {
                set req.url = regsub(req.url, "\?.*", "");
        }

        ## Cache all others requests if they reach this point.
        # I'm still thinking if bypassing in-build logic this way is a smart move.
        return(hash);

# The end
}


##############vcl_pipe################
#

sub vcl_pipe {

        ## Pipe counter
        set req.http.x-cache = "pipe uncacheable";

        ## Implementing websocket support
        if (req.http.upgrade) {
                set bereq.http.upgrade = req.http.upgrade;
                set bereq.http.connection = req.http.connection;
        }

# This stops here
}



################vcl_hash##################
#
sub vcl_hash {

	## Return of User-Agent, but without caching
	# Now I can send User-Agent to backend for 404 logging etc.
	# Vary must be cleaned of course
	if (req.http.x-agent) {
		set req.http.User-Agent = req.http.x-agent;
		unset req.http.x-agent;
	}

# The end of hashing
}
################vcl_pass################
#

sub vcl_pass {

        ## Pass counter
        set req.http.x-cache = "pass";

# the pass ends here
}



###################vcl_hit#########################
#

sub vcl_hit {

        ## Pure hit
        if (obj.ttl >= 0s) {
            set req.http.x-cache = "hit";
            return (deliver);
        }

        ## Out of TTL, but is under grace
        # I'm using very short grace, like 15 secs or something
        if (obj.ttl <= 0s && obj.grace > 0s) {
            set req.http.x-cache = "hit graced";
            std.log("HIT grace: " + req.url);
            return (deliver);
        }

        
# End of the hit, Jack
}



###################vcl_miss#########################
#

sub vcl_miss {

        ## Miss counter
        set req.http.x-cache = "miss";

# Last call miss
}


#### vcl_backend_response ####
#

sub vcl_backend_response {

        ## Add name of backend in varnishncsa log. The name is shown only if backend responds.
        # You can find slow replying backends (over 3 sec) with that:
        # varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' | awk '$7 > 3 {print}'
        # or
        # varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' -q "Timestamp:Beresp[3] > 3 or Timestamp:Error[3] > 3"
        std.log("backend: " + beresp.backend.name);

        ## Let's create a couple helpful tag'ish
        set beresp.http.x-url = bereq.url;
        set beresp.http.x-host = bereq.http.host;

	## Backend is down, stop caching but using ttl+grace instead
	if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {
		if (bereq.is_bgfetch) {
			return(abandon);
		}
		set beresp.uncacheable = true;
	}

        # There is no HSTS or Secure-flags in onion
        unset beresp.http.Strict-Transport-Security;

        # Do not allow cookies from a backend
        if (beresp.http.Set-Cookie) { 
                unset beresp.http.Set-Cookie;
	}

        # Optional: block 3rd party scripts
        # set beresp.http.Content-Security-Policy = "default-src 'self' data:; img-src 'self' data: https:; script-src 'self'; style-src 'self' 'unsafe-inline'; frame-ancestors 'self'; object-src 'none'";

        ## Ordinary default; how long Varnish will keep objects
        # Varnish is using beresp.ttl as s-maxage (max-age is for browser),
        # This is default, and can or will be overdriven later.
        if ( beresp.status == 200 || beresp.ttl > 0s) {
                unset beresp.http.Expires;
                unset beresp.http.Cache-Control;
                unset beresp.http.Pragma;
		unset beresp.http.Set-Cookie;

                # Set how long Varnish will keep it
                # Varnish will keep cache very long time. Most of content never changes.
                # There will be systen reboot or WordPress updates that does purge, as does Varnish restarts,
                # and on other hand cache warmer and all those changes and refreshes
                # the actual cache no matter this setting
                set beresp.ttl = 52w;

                # 24h for browsers, 365d for Varnish using beresp.ttl as a fallback. 
                # s-maxage is for other intermediate caches.
                # This hits in if there is no cache-control in use
                set beresp.http.Cache-Control = "public, max-age=86400, s-maxage=31536000;";

                # Helps to group requests in varnishlog. Just for debugging.
                #set beresp.http.X-Varnish = bereq.xid;
        }

        ## This is for local audio only, if any
        if (beresp.http.Content-Type ~ "^(audio)/" || bereq.url ~ "\.mp3") {
                unset beresp.http.set-cookie;
                unset beresp.http.Cache-Control;
                set beresp.http.Cache-Control = "public, max-age=7200s"; # 2h
                set beresp.ttl = 30d;
                set beresp.do_stream = true;
                # some logging here too
                set beresp.http.X-Cache-Control = "pass: streamed audio";
        }

	## Missing one can be found
	if (beresp.status == 404) {
		set beresp.ttl = 120s;
		set beresp.uncacheable = true;
	}

	## Error 410 are steady and lives forever
        if (beresp.status == 410) {
                unset beresp.http.Set-Cookie;
                unset beresp.http.Cache-Control;
                # Must set, because default is only for 200
                set beresp.http.Cache-Control = "public, max-age=86400"; # 24h
                set beresp.ttl = 52w;
        }

        ## Let' build Vary
        # first cleaning it, because we don't care what backend wants.
        unset beresp.http.Vary;

        # Accept-Encoding could be in Vary, because it changes content
        # But it is handled internally by Varnish.
        set beresp.http.Vary = "Accept-Encoding";

        # User-Agent was sended to backend, but removing it from Vary prevents Varnish to use it for caching
        # Is this really needed? I removed UA and backend doesn't set it up, but uses what it gets from http.req
        if (beresp.http.Vary ~ "User-Agent") {
                set beresp.http.Vary = regsuball(beresp.http.Vary, ",? *User-Agent *", "");
                set beresp.http.Vary = regsub(beresp.http.Vary, "^, *", "");
                if (beresp.http.Vary == "") {
                        unset beresp.http.Vary;
                }
        }

        ## Unset the old pragma header
        # Unnecessary filtering 'cos Varnish doesn't care of pragma, but it is ugly in headers
        # AFAIK WordPress doesn't use Pragma, so this is unnecessary here.
        unset beresp.http.Pragma;

# The End
}


#######################vcl_deliver#####################
# Now the content is fetched from the backend or cache and is ready to be delivered to users
#

sub vcl_deliver {

	## Helping the server to stay on onion side
	if (req.http.X-Pseudo) {
		set resp.http.X-Onion = "1";
	} else {
		unset resp.http.X-Onion;
	}

	## Damn, backend is down (or the request is not allowed; almost same thing)
	if (resp.status == 503) {
		return(restart);
	}

	## Hit counter
        if (obj.hits > 0) {
                # I don't fancy boring hit/miss announcements
                set resp.http.You-had-only-one-job = "Success";
        } else {
                set resp.http.You-had-only-one-job = "Phew";
        }

	## Hiding headers
        unset resp.http.x-url;
        unset resp.http.x-host;
        unset resp.http.xkey;
	unset resp.http.Last-Modified;
        unset resp.http.Expires;
        unset resp.http.Pragma;
        unset resp.http.Server;
        unset resp.http.X-Powered-By;
        unset resp.http.Via;
        #unset resp.http.Link;
        unset resp.http.X-Generator;
        unset resp.http.x-url;
        unset resp.http.x-host;
        unset resp.http.X-Varnish;
	unset resp.http.X-Onion;
        unset resp.http.X-dlm-no-waypoints;
        unset resp.http.X-UA-Compatible;
	unset resp.http.X-Cache-Tags;
	unset resp.http.Expires

        ## Vary to browser
        set resp.http.Vary = "Accept-Encoding";

        ## Origin should send to browser
        set resp.http.Vary = resp.http.Vary + ",Origin";

	## Return of lang
	set resp.http.Accept-Language = std.tolower(req.http.Accept-Language);
	unset req.http.Accept-Language;
	if (req.http.x-language ~ "fi") {
		set req.http.x-language = "fi";
	} else {
		unset req.http.x-language;
	}

# The end here
}


#### vcl_synth ####
#
sub vcl_synth {

	if (resp.status == 301 && req.http.X-Redirect-Target) {
		set resp.http.Location = req.http.X-Redirect-Target;
		set resp.http.Cache-Control = "no-store";
	}

	return (deliver);

# That's it
}


####################### vcl_fini #######################
#

sub vcl_fini {

  ## Called when VCL is discarded only after all requests have exited the VCL.
  # Typically used to clean up VMODs.

  return(ok);
}
