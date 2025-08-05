## Jakke Lehtonen
## 
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.7.1 default.vcl/shared_wp.vcl for multiple virtual hosts
## 
## shared_wp.vcl, same as default.vcl, is splitted in few sub vcls. Those use includes.  
## That make updating much more easier, because most of my hosts are WordPresses.
##
## This works as a standalone VCL for one WordPress host too
##  
## Lets's start caching (...and a little bit more)
 
########
 
# Marker to tell the VCL compiler that this VCL has been adapted to the 4.1 format.
vcl 4.1;

# native ones
import std;		# Load the std, not STD for god sake
import cookie;		# Load the cookie, former libvmod-cookie
import purge;		# Soft/hard purge by Varnish 7.x

# From combiled varnish-modules
import xkey;		# another way to ban

## Includes are normally in vcl

# Block using ASN
include "/etc/varnish/include/asn_id.vcl";
include "/etc/varnish/include/generated/asn_blocklist.vcl";

# Pure normalizing and similar, normally done first
include "/etc/varnish/include/normalize.vcl";

# Cleaning user-agents
include "/etc/varnish/include/real_users.vcl";
include "/etc/varnish/include/probes.vcl";
include "/etc/varnish/include/nice_bots.vcl";

# Kill useless knockers
include "/etc/varnish/include/recv/6-malicious_url.vcl";
include "/etc/varnish/include/recv/match_config_attack.vcl";
include "/etc/varnish/include/recv/match_env_attack.vcl";
include "/etc/varnish/include/recv/match_other_attack.vcl";
include "/etc/varnish/include/recv/match_php_attack.vcl";
include "/etc/varnish/include/recv/match_sql_attack.vcl";
include "/etc/varnish/include/recv/match_wp_attack.vcl";

# Manipulating some urls
include "/etc/varnish/include/recv/7-manipulate.vcl";

# Is there ban or purge, and who can do it
include "/etc/varnish/include/recv/8-ban_purge.vcl";

# vcl_backend_response, part IV - TTL
include "/etc/varnish/include/backend_response/4-ttl.vcl";
include "/etc/varnish/include/backend_response/conditional410.vcl";
include "/etc/varnish/include/backend_response/ttl_debug.vcl";

# vcl_synth, all errors
include "/etc/varnish/include/erroed.vcl";

# Some security related headers
include "/etc/varnish/include/security.vcl";

## Debugs
#include /etc/varnish/include/debug/wordpress_debug.vcl

## Backend tells where a site can be found

# WordPress
backend sites {
	.host = "127.0.0.1";
	.port = "8282";
	.max_connections = 5000;
	.first_byte_timeout = 300s;
	.connect_timeout = 300s;
	.between_bytes_timeout = 300s;
#	.probe = sondi;
}

# Apache2 has fallen down
backend snapshot {
	.host = "127.0.0.1";
	.port = "8383";
}

## About IPs: I can't use client.ip because it is always 127.0.0.1 by Nginx (or any proxy like Apache2)
# Instead client.ip it has to be like std.ip(req.http.X-Real-IP, "0.0.0.0")
# For IP whitelisting I have X-Bypass header by Nginx and then I can do this:
# req.http.X-Bypass != "true"

#################### vcl_init ##################
# Called when VCL is loaded, before any requests pass through it. Typically used to initialize VMODs.
# You have to define server at backend definition too.

sub vcl_init {
	
	
# The end of init
}


############### vcl_recv #################
## We should have here only statments without return(...) or is must be unconditionally and stop process
## The solution has explained here: https://www.getpagespeed.com/server-setup/varnish/varnish-virtual-hosts
## Here we are telling to Varnish what to do and what to cache or not. This is not for backend or i.e. browsers

sub vcl_recv {

	## All normal and we use this backend
	set req.backend_hint = sites;

        ## Just normalizing host names
        # I like to keep triple-w

        set req.http.host = regsub(req.http.host,
        "^katiska\.eu$", "www.katiska.eu");

        set req.http.host = regsub(req.http.host,
        "^eksis\.one$", "www.eksis.one");

        set req.http.host = regsub(req.http.host,
        "^poochierevival\.info$", "www.poochierevival.info");

        ## Give 127.0.0.1 to X-Real-IP if curl is used from localhost
        # (std.ip(req.http.X-Real-IP, "0.0.0.0") goes to fallbck when curl is used from localhost and fails
        # Because Nginx acts as a reverse proxy, client.ip is always its IP.
        # Now we get some IP when worked from home shell
        # This should or could be among other normalizin, but I want this before bot filtering
        if (!req.http.X-Real-IP || req.http.X-Real-IP == "") {
                set req.http.X-Real-IP = client.ip;
        }

        ## just for these virtual hosts
        # for stop caching uncomment
        #return(pass);
        # for dumb TCL-proxy uncomment
        #return(pipe);

	## certbot gets bypass route
	if (req.http.User-Agent ~ "certbot") {
		set req.backend_hint = sites;
		return(pipe);
	}

	### The work starts here

	## Nginx deals with countries and user-agents, but one is left: ASN
        ## If you have just another website for real users maybe It is wise move to ban every single one VPS service
        ## you don't need for APIs etc.
        # Heads up: ASN can and quite often will stop more than just one company
        # Just coming from some ASN doesn't be reason to hard banning,
        # but everyone here is knocking too often so I'll keep doors closed

        ## ASN can be empty sometimes. Nginx changes it to unknown for easier reading. 
        # I stop those request, because it is suspicious
        if (req.http.X-ASN-ID == "unknown") {
                std.log("Missing ASN-ID: " + req.http.X-Real-IP + " " + req.http.Country-Code);
                return(synth(400, "Missing ASN-ID"));
        }

        # Let`s filtering
        call asn_id;
        call asn_blocklist;

        ## Tidying a little bit places before the work starts.
        # Reset hit/miss counter
        unset req.http.x-cache;

        # Just to on safe side, if there is i.e. return(pass/restart) that comes from a situation that can mess things
        unset req.http.X-Saved-Origin;

	## Normalizing, as hosts, https, country-code etc.
	call normalize;

        ## Central station for tidying user-agents.
        ## I could normalize UA, but nowadays I leave is as it is, and adding two x-headers:
        ## x-bot and x-user-agent

        # These should be marked as real users, but some aren't
        call real_users;

        # Technical probes
        # These are useful and I want to know if backend is working etc.
        if (req.http.x-bot != "visitor") {
                call probes;
        }

        # These are nice bots, and I'm normalizing UA a bit
        if (req.http.x-bot !~ "(visitor|tech)$") {
                call nice_bots;
        }
		
	## Huge list of urls and pages that are constantly knocked
	# There is no one to listening, but those are still hammering backend
	# acting like low level ddos.
	# So I waste money and resources to give an error to them
	call malicious_url-6;

	## If a user agent isn't identified as user or a bot, its type is unknown.
	# We must presume it is a visitor. 
	# There is big chance it is bot/scraper, but we have false identifications anyway. 
	if (!req.http.x-user-agent) {
                set req.http.x-user-agent = "Unlisted: " + req.http.User-Agent;
		set req.http.x-bot = "visitor";
        }
		
	## URL changes, mostly fixed search strings
	if (req.http.x-bot == "visitor") {
		call manipulate-7;
	}
	
	## Ban & Purge
	if (req.method == "BAN" || req.method == "PURGE") {
		call ban_purge-8;
	}
	
	## Setup CORS
	# Incoming
        if (req.http.Origin) {
                std.log("CORS check: incoming request with Origin: " + req.http.Origin + " → URL: " + req.url);

        # Whitelist allowed origins using regular expression
        if (req.http.Origin ~ "^(https://www\.katiska\.eu|https://www\.eksis.\.one|https://www\.poochierevival\.info)$") {
                set req.http.X-Saved-Origin = req.http.Origin;
                std.log("CORS accepted: " + req.http.Origin);
        } else {
                std.log("CORS denied: " + req.http.Origin);
                }
        }

	### WordPress related

        ## Fix Wordpress visual editor and login issues, must be the first url pass requests and
        # before cookie monster to work.
        # Backend of Wordpress
        if (req.url ~ "^/wp-(login|admin|cron|comments-post\.php)" || req.url ~ "(preview=true|/login|/my-account)") {
                return(pass);
        }

        ## Don't cache logged-in user, password reseting and posts behind password
        if (req.http.Cookie ~ "wordpress_logged_in_" || req.http.Cookie ~ "wp-postpass_" || req.http.Cookie ~ "resetpass") {
                return(pass);
        }

        ## Don't cache auth, i.e. if REST API needs it.
        if (req.http.Authorization) {
                return(pass);
        }

        ## Cookie monster: Keeping needed cookies and deleting rest.
        if (req.http.cookie) {
                cookie.parse(req.http.cookie);

                # Remove analytics and follower cookies
                # AFAIK this not needed, because next logic says what cookies are allowed and dumps rest
                cookie.delete("__utm, _ga, _gid, _gat, _gcl, _fbp, fr, _pk_, FCNEC, __eoi");

                # Keep necessary WordPress cookies
                cookie.keep("wordpress_logged_in_,wp-settings,wp-settings-time,_wp_session,resetpass");

                set req.http.cookie = cookie.get_string();

                # Don' let empty cookies travel any further
                if (req.http.cookie == "") {
                        unset req.http.cookie;
                }
        }


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
        if (req.url ~ "^/(signup|activate|mail|logout)(/|$)") {
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

	# If needed
	#call wordpress_debug;


        ## Let's clean User-Agent, just to be on safe side
        # It will come back at vcl_hash, but without separate caching
        # I want send User-Agent to backend because that is the only way to show who is actually getting error 404; 
        # I don't serve bots  and 404 from real users must fix right away
        set req.http.x-agent = req.http.User-Agent;
        if (req.http.x-bot !~ "(nice|tech|bad|visitor)") { set req.http.x-bot = "visitor"; }
        unset req.http.User-Agent;

        ## Because vmod Accept isn't in use, we have to remove Accept-Language, because there is no need to cache with it.
        # Let's tranfer to response anyway
        set req.http.x-language = req.http.Accept-Language;
        unset req.http.Accept-Language;

        ## I don't need separated caches used by country code, but I use it in responses
        set req.http.x-country = req.http.X-Country-Code;
        unset req.http.X-Country-Code;

	## Cache all others requests if they reach this point.
	# I'm still thinking if bypassing in-build logic this way is a smart move.
	return(hash);

# End of recv	
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

# The end of the pipe
}


################vcl_pass################
#
sub vcl_pass {

        ## Pass counter
        set req.http.x-cache = "pass";

# the pass ends here
}


################vcl_hash##################
#
sub vcl_hash {

        ## Caching per language, that's why we normalized this
        # Because I don't have multilingual, I clean Accept-Language
        # I have one site pure English, but is not Content-Language enough?
        #hash_data(req.http.Accept-Language);

        ## Return of User-Agent and Accept-Language, but without caching
        
        # Now I can send User-Agent to backend for 404 logging etc.
        # Vary must be cleaned of course
        if (req.http.x-agent) {
                set req.http.User-Agent = req.http.x-agent;
                unset req.http.x-agent;
        }
        
        # Same thing with Accept-Language
        if (req.http.x-language) {
                set req.http.Accept-Language = req.http.x-language;
                unset req.http.x-language;
        }

        # And again with X-Country-Code
	# I reckon this is totally unnecessary. X-headers aren't user for hash/caching per se.
        if (req.http.x-country) {
                set req.http.X-Country-Code = req.http.c-country;
                unset req.http.x-country;
        }

# The end for hash

	# HEADS UP!
	# Allowing lookup here will bypass in-build rules, and then you MUST hash host, server and url.
	# If you not, your cache will be totally mess.
#	return(lookup);

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

        ## Banned or badly stale
        std.log("Banned HIT, fetch fresh copy: " + req.url);
        return (pass);	
	
# End of the hit, Jack
}


###################vcl_miss#########################
#
sub vcl_miss {

        ## Miss counter
        set req.http.x-cache = "miss";

# Last call miss
}


###################vcl_backend_fetch###############
#
sub vcl_backend_fetch {

	## Used when backend is down, and extra header is needed for Nginx
	if (bereq.backend == snapshot) {
             set bereq.http.X-Emergency-Redirect = "true";
	}

# fetch stops here
}


###################vcl_backend_response#############
# This will alter everything what a backend responses back to Varnish
# Affets to what i.e. browsers will do

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

        ## Backend is down: start Snapshot routines 

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

        # If backend is down we move to snapshot backend that serves static content, when not in cache.
        # But Varnish uses 200 OK, because it got content, but we don't want to tell to bots that temp content is 200
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
                        std.syslog(180, "Backend failure, marking response uncacheable: " + bereq.http.host + bereq.url);
                        set beresp.uncacheable = true;
                }
        }

        ## xkey
	# set tags
        if (beresp.http.X-Cache-Tags) {
            set beresp.http.xkey = beresp.http.X-Cache-Tags;
        }

        # Add domain-xkey if not already there
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

        # Add xkey for tags if not already there
        if (bereq.url ~ "^/") {
            # This trick must be done beacuse strings can't be joined with regex-operator
            set beresp.http.X-URL-CHECK = "url-" + bereq.url;

            if (!std.strstr(beresp.http.xkey, beresp.http.X-URL-CHECK)) {
                set beresp.http.xkey += "," + beresp.http.X-URL-CHECK;
            }

            unset beresp.http.X-URL-CHECK;
        }

	## TTLs and uncacheables
	call ttl-4;

	
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


        ## Unset Accept-Language, if backend gave one. I still want to keep it outside cache.
        unset beresp.http.Accept-Language;

        ## Unset the old pragma header
        # Unnecessary filtering 'cos Varnish doesn't care of pragma, but it is ugly in headers
        # AFAIK WordPress doesn't use Pragma, so this is unnecessary here.
        unset beresp.http.Pragma;

# We are at the end of responses
}


#######################vcl_backend_error###############
## Tells what to when backend doesn`t give suitable answers and backend_response can't do anything
## The default action is return(deliver)
## Normally this block isn't visible. I'm using it for snapshot_service when backend is down
sub vcl_backend_error {

    ## There isn't a retry yet, so do it to find out if this is really happening
    if (bereq.retries == 0) {
        std.syslog(180, "ALERT: Apache is not responding on first attempt: " + bereq.http.host + bereq.url);
        std.log("Backend error: first retry");
        return (retry);
    }

    ## First retry is done and backend is still down. Change to snapshot-server.
    if (bereq.retries == 1 &&
        (beresp.status == 500 || beresp.status == 503 || beresp.status == 504)) {
        std.log("Backend error: switching to snapshot backend");
        set bereq.backend = snapshot;
        return (retry);
    }

    ## Nothing works and now it's time to show error
    std.syslog(180, "ALERT: snapshot and Apache2 down " + bereq.http.host + bereq.url);
    std.log("Backend error: all retries failed");
    return (fail);

# We are ready with errors
}


#######################vcl_deliver#####################
# Now the content is fetched from the backend or cache and is ready to be delivered to users
#

sub vcl_deliver {

        ## Damn, backend is down (or the request is not allowed; almost same thing)
        if (resp.status == 503) {
                return(restart);
        }
        
        ## Knockers with 404 will get synthetic error 666 that leads to real error 666
        if (resp.status == 666) {
                return(synth(666, "Requests not allowed for " + req.url));
        }

        ## Just some unneeded headers showing unneeded data

        # HIT & MISS
        if (obj.uncacheable) {
                set req.http.x-cache = req.http.x-cache + " uncacheable" ;
        } else {
                set req.http.x-cache = req.http.x-cache + " cached" ;
        }
        # uncomment the following line to show the information in the response
        set resp.http.x-cache = req.http.x-cache;

        if (obj.hits > 0) {
                # I don't fancy boring hit/miss announcements
                set resp.http.You-had-only-one-job = "Success";
        } else {
                set resp.http.You-had-only-one-job = "Phew";
        }

        # Show hit counts (per objecthead)
        # Same here, something like X-total-hits is just boring
        if (obj.hits > 0) {
                set resp.http.Footprint-of-CO2 = (obj.hits) + " metric-tons";
        } else {
                set resp.http.Footprint-of-CO2 = "Greenwash in progress";
        }

        ## Debug for 403
        #if (resp.status == 403) {
        #       call debug_headers;
        #}

        ## Logs short and close to expire TTLs
        if (obj.ttl < 3600s && !obj.uncacheable) {
                std.log("SHORT_TTL_DELIVER: " + req.url +
                        " HIT/MISS=" + resp.http.X-Cache +
                        " TTL=" + obj.ttl);
        }

        ## Logs ttl of the most used images
        if (req.url ~ "(?i)\.(jpeg|jpg|png|webp)(\?.*)?$") {
                std.log("IMAGE_TTL_DELIVER: " + req.url +
                        " HIT/MISS=" + resp.http.X-Cache +
                        " TTL=" + obj.ttl);
                std.syslog(150, "IMAGE_TTL_DELIVER: " + req.url +
                                " HIT/MISS=" + resp.http.X-Cache +
                                " TTL=" + obj.ttl);
        }

        ## Logs ttl of MP3s
        if (req.url ~ "\.mp3(\?.*)?$") {
                std.log("MP3_TTL_DELIVER: " + req.url +
                        " HIT/MISS=" + resp.http.X-Cache +
                        " TTL=" + obj.ttl);
                std.syslog(150, "MP3_TTL_DELIVER: " + req.url +
                                " HIT/MISS=" + resp.http.X-Cache +
                                " TTL=" + obj.ttl);
        }

        ## And now I remove my helpful tag'ish
        # Now something like this works:
        # varnishlog -c -g request -i Req* -i Resp* -I Timestamp:Resp -x ReqAcct -x RespUnset -X "RespHeader:(x|X)-(url|host)" 
        unset resp.http.x-url;
        unset resp.http.x-host;
#       unset resp.http.xkey;

        ## Vary to browser
        set resp.http.Vary = "Accept-Encoding";

        ## Origin should send to browser
        set resp.http.Vary = resp.http.Vary + ",Origin";

        ## Set xkey visible
        if (resp.http.X-Cache-Tags) {
                set resp.http.X-Cache-Tags = resp.http.X-Cache-Tags;
        }

	## Outgoing part of cors
        if (req.http.X-Saved-Origin) {
                set resp.http.Access-Control-Allow-Origin = req.http.X-Saved-Origin;
                set resp.http.Access-Control-Allow-Methods = "GET, POST, OPTIONS";
                set resp.http.Access-Control-Allow-Headers = "Content-Type, Authorization";
                set resp.http.Access-Control-Allow-Credentials = "true";
                set resp.http.X-CORS-Debug = "Enabled for " + req.http.X-Saved-Origin;
        } else {
                unset resp.http.Access-Control-Allow-Origin;
                unset resp.http.Access-Control-Allow-Methods;
                unset resp.http.Access-Control-Allow-Headers;
                unset resp.http.Access-Control-Allow-Credentials;
                unset resp.http.X-CORS-Debug;
        }

	## A little bit more security using some headers
	# CSP is done in WordPresses
	call security;
		
        ## Last-Modified timestamp may be interesting for users, but unnecessary
        # but I want to mask it a little bit, and show it, because I'm curious, even curiosity kills the cat
        # Last-Modified comes only from backend. Cached content hasn't it.
        if (!resp.http.Last-Modified || resp.http.Last-Modified == "") {
                unset resp.http.Last-Modified;          
        }
        else {
                set resp.http.those-good-old-days = resp.http.Last-Modified;
                unset resp.http.Last-Modified;
        }
        
        ## Just to be sure who is seeing what
        if (req.http.x-bot) {
                set resp.http.debug = req.http.x-bot;
        }
        
        ## Expires and Pragma are unneeded because cache-control overrides it
        unset resp.http.Expires;
        unset resp.http.Pragma;
        
        ## Remove some headers, because the client doesn't need them
        unset resp.http.Server;
        unset resp.http.X-Powered-By;
        unset resp.http.Via;
        #unset resp.http.Link;
        unset resp.http.X-Generator;
        unset resp.http.x-url;
        unset resp.http.x-host;
        
        # Why? I don't know
        set resp.http.X-Varnish = req.http.X-Varnish;
        unset resp.http.X-Varnish;
        # Custom headers, not so serious thing 
        set resp.http.Your-Agent = req.http.User-Agent;
        set resp.http.Your-IP = req.http.X-Real-IP;
        #set resp.http.Your-Language = req.http.Accept-Language;

	## Don't show funny stuff to bots
	if (req.http.x-bot == "visitor") {
		# lookup can't be in sub vcl
		set resp.http.Your-IP-Country = std.toupper(req.http.X-Country-Code);
	}

# That's delivered
}


##################vcl_synth######################
# All synthetic errors
#
sub vcl_synth {

	## Synth counter
	# not is a sub vcl to get easier site by site setting
	set req.http.x-cache = "synth synth";
	# uncomment the following line to show the information in the response
	# set resp.http.x-cache = req.http.x-cache;
	
	## Must handle cors here too
	# was: call cors; so exacly what cors should I call here? Fix this.
	# This I had, but can't understand why: call cors_deliver;
	
	## Synth errors, real on customs
	# include/erroed.vcl
	call errored;

	## Needed here, I suppose
	return (deliver);

# End of sub
} 


####################### vcl_fini #######################
#

sub vcl_fini {

  ## Called when VCL is discarded only after all requests have exited the VCL.
  # Typically used to clean up VMODs.

  return(ok);
}
