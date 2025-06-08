## Jakke Lehtonen
## 
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.1.1 default.vcl for multiple virtual hosts
## 
## default.vcl is splitted in several sub vcls. That make updates much more easier
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

# from geoip package, needs separate compiling per Varnish version
#import geoip2;		# Load the GeoIP2 by MaxMind

# from apt install varnish-modules but it needs same Varnish version that repo is delivering
# I compiled, but it was still claiming Varnish was in apt-given version, even it was newer.
# So I gave up with newer ones.
#import accept;		# Fix Accept-Language
import xkey;		# another way to ban

## includes are normally in vcl
# www-domains need normalizing
#include "/etc/varnish/include/normalize_host.vcl";

# Debugging 403 errors
include "/etc/varnish/include/debug_headers.vcl";

# Let's cleanup first, lightlu
#include "/etc/varnish/include/clean_up.vcl";

# Pure normalizing and similar, normally done first
#include "/etc/varnish/include/normalize.vcl";

# Is there ban or purge, and who can do it
#include "/etc/varnish/include/ban_purge.vcl";

# Something must do before cookies are cleaned
#include "/etc/varnish/include/pre-wordpress.vcl";

# Cleaning cookies for WordPress
#include "/etc/varnish/include/cookie_monster.vcl";

# Setting up pipe/pass/hash etc. what WordPress wants
#include "/etc/varnish/include/wordpress.vcl";

# There is still something to do before leaving vcl_recv
#include "/etc/varnish/include/last_ones.vcl";

# vcl_pipe
include "/etc/varnish/include/piped.vcl";

# vcl_miss
include "/etc/varnish/include/missed.vcl";

# vcl_pass
include "/etc/varnish/include/passed.vcl";

# vcl_hash
include "/etc/varnish/include/hashed.vcl";

# vcl_hit
include "/etc/varnish/include/hited.vcl";

# vcl_purge
include "/etc/varnish/include/purged.vcl";

# vcl_backend_response, part I
include "/etc/varnish/include/be_start.vcl";

# vcl_backend_response, part II - TTL
include "/etc/varnish/include/be_ttl.vcl";

# vcl_backend_response, part III
include "/etc/varnish/include/be_end.vcl";

# vcl_backend_response, pat IV, xkey
include "/etc/varnish/include/x-key.vcl";

# vcl_deliver, part I
include "/etc/varnish/include/delivered.vcl";

# vcl_deliver, part II, counters
include "/etc/varnish/include/counters.vcl";

# vcl_deliver, part III, headers
include "/etc/varnish/include/showed.vcl";

# vcl_synth, all errors
include "/etc/varnish/include/erroed.vcl";

## ext are something extra
# Kill useless knockers
#include "/etc/varnish/ext/403.vcl";
#include "/etc/varnish/ext/malicious_url.vcl";
#include "/etc/varnish/ext/match_config_attack.vcl";
#include "/etc/varnish/ext/match_env_attack.vcl";
#include "/etc/varnish/ext/match_other_attack.vcl";
#include "/etc/varnish/ext/match_php_attack.vcl";
#include "/etc/varnish/ext/match_sql_attack.vcl";
#include "/etc/varnish/ext/match_wp_attack.vcl";

# Block using ASN
#include "/etc/varnish/ext/asn_blocklist_start.vcl";
#include "/etc/varnish/ext/asn.vcl";
#include "/etc/varnish/ext/asn_blocklist.vcl";

# Human's user agent
#include "/etc/varnish/ext/user-ua.vcl";

# Tools and libraries
#include "/etc/varnish/ext/probes.vcl";

# Bots with purpose
#include "/etc/varnish/ext/nice-bot.vcl";

# Manipulating some urls
#include "/etc/varnish/ext/manipulate.vcl";

# Conditional 410
include "/etc/varnish/ext/410conditional.vcl";

# CORS can be handful, so let's give own VCL
include "/etc/varnish/ext/cors.vcl";

# Some security related headers
include "/etc/varnish/ext/security.vcl";

## Probes are watching if backends are healthy
## You can check if a backend is  healthy or sick:
## varnishlog -g raw -i Backend_health

probe sondi {
    #.url = "/healthcheck.txt";  # or you can use just an url
	# you must have installed libwww-perl:
    .request =
      "GET /healthcheck.txt HTTP/1.1"
      "Host: www.katiska.eu"		# It controls whole backend using one site; not the best option
      "Connection: close"
      "User-Agent: Varnish Health Probe";
	.timeout = 5s;
	.interval = 4s;
	.window = 5;
	.threshold = 3;
}

# Force to sick: varnishadm -S /etc/varnish/secret -T localhost:6082 backend.set_health crashed sick
# Force to healthy: varnishadm -S /etc/varnish/secret -T localhost:6082 backend.set_health crashed healthy
# Back to auto: varnishadm -S /etc/varnish/secret -T localhost:6082 backend.set_health crashed auto
# Check status: varnishadm -S /etc/varnish/secret -T localhost:6082 backend.list
# Debug status: varnishadm -S /etc/varnish/secret -T localhost:6082 debug.health 

## Backend tells where a site can be found

# WordPress
backend sites {
	.host = "127.0.0.1";
	.port = "8282";
	.max_connections = 5000;
	.first_byte_timeout = 300s;
	.connect_timeout = 300s;
	.between_bytes_timeout = 300s;
	.probe = sondi;
}

# Apache2 has fallen down
backend emergency_nginx {
	.host = "127.0.0.1";
	.port = "8283";
}
## ACLs: I can't use client.ip because it is always 127.0.0.1 by Nginx (or any proxy like Apache2)
# Instead client.ip it has to be like std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist
# Heads up! ACL must be in use, if uncommented.
 
# This can do almost everything
acl whitelist {
	"localhost";
	"127.0.0.1";
	"157.180.74.208";
	"37.27.18.60";
	"37.27.188.104";
	"85.76.112.42";
}


#################### vcl_init ##################
# Called when VCL is loaded, before any requests pass through it. Typically used to initialize VMODs.
# You have to define server at backend definition too.

sub vcl_init {
	
	## GeoIP
	#new country = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-Country.mmdb");
	#new city = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-City.mmdb");
	#new asn = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-ASN.mmdb");
	
	## Accept-Language
	## Diffent caching for languages. I don't have multilingual sites, though.
	#new lang = accept.rule("fi");
	#lang.add("sv");
	#lang.add("en");
	
# The end of init
}


############### vcl_recv #################
## We should have here only statments without return(...) or is must be unconditionally and stop process
## The solution has explained here: https://www.getpagespeed.com/server-setup/varnish/varnish-virtual-hosts
## Here we are telling to Varnish what to do and what to cache or not. This is not for backend or i.e. browsers

sub vcl_recv {

	## If the backend is done, we change to emergency mode
	if (!std.healthy(sites)) {
		set req.backend_hint = emergency_nginx;
		return (pipe);
	}

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

        ## just for this virtual host
        # for stop caching uncomment
        #return(pass);
        # for dumb TCL-proxy uncomment
        #return(pipe);

	### The work starts here

	## certbot gets bypass route
	if (req.http.User-Agent ~ "certbot") {
		set req.backend_hint = sites;
		return(pipe);
	}

	## Give 127.0.0.1 to X-Real-IP if curl is used from localhost
	# (std.ip(req.http.X-Real-IP, "0.0.0.0") goes to fallbck when curl is used from localhost and fails
	# Because Nginx acts as a reverse oroxy, client.ip is always its IP.
	# Now we get some IP when worked from home shell
	if (!req.http.X-Real-IP || req.http.X-Real-IP == "") {
		set req.http.X-Real-IP = client.ip;
	}

	## Forbidden means forbidden
	# Nginx deals with countries and user-agents, but one is left: ASN
	#call asn_name;
#	call asn_blocklist_start;

	### Tidying a little bit places before the work starts.

	## Reset hit/miss counter
        unset req.http.x-cache;

	## Just to on safe side, if there is i.e. return(pass/restart) that comes from a situation that can mess things
	unset req.http.X-Saved-Origin;

	## Googlebot is flooding with this and filling logs. Now it can't reach the backend
	# I'm doing this in Nginx and not logging.
	# This helps server wide and returns 410, if wanted:
	# if ($arg_taxonomy ~* "^(amp_validation_error|knowledgebase_tag|.*_error)$") {
	# return 410 "Gone. This taxonomy never existed.\n";
	# }
	if (req.url ~ "taxonomy=") {
		return(synth(811, "Gone. This taxonomy never existed.\n")); # synth 410 only for this purpose
	}

	## Redirecting http/80 to https/443
        # This could, and perhaps should, do in Nginx, but certbot likes this better
        if ((req.http.X-Forwarded-Proto && req.http.X-Forwarded-Proto != "https") ||
        (req.http.Scheme && req.http.Scheme != "https")) {
                return(synth(750));
        }

	### Here we move into sub-world

	## It will terminate badly formed requests
        ## Build-in rule. But works only if there isn't return(...) that forces jump away
        if (!req.http.host && req.esi_level == 0 && req.proto ~ "^(?i)HTTP/1.1") {
                # In HTTP/1.1, Host is required.
                return (synth(400));
        }
       
        ## Let's clean up Proxy.
        # It comes from dumb TSL-proxies like Hitch
        # This is old security measurement too
        unset req.http.Proxy;

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

        ## Some devices, mainly from Apple, send urls ending /null
        if (req.url ~ "/null$") {
                set req.url = regsub(req.url, "/null", "/");
        }

	std.log(">> DEBUG: vcl_recv start");

	if (req.url ~ "^/wp-(login|admin|cron|comments-post\.php)" || req.url ~ "(preview=true|/login|/lataus|/my-account)") {
		std.log(">> DEBUG: return(pass) due to first admin rules");
		return(pass);
	}

	## Don't cache logged-in user, password reseting and posts behind password
	# Could be after cookie monster, but let be is safe side bedfore cookies are messed
	if (req.http.Cookie ~ "wordpress_logged_in_" || req.http.Cookie ~ "wp-postpass_" || req.http.Cookie ~ "resetpass") {
		std.log(">> DEBUG: return(pass) due to logged in + cookies");	
		return(pass);
	}

	## Don't cache auth, i.e. if REST API needs it.
	if (req.http.Authorization) {
		std.log(">> DEBUG: return(pass) due to Authorization");
		return(pass);
	}

	## Cookie monster: Keeping needed cookies and deleting rest.
	if (req.http.cookie) {
		cookie.parse(req.http.cookie);

		# Remove analytics and follower cookies
		cookie.delete("__utm, _ga, _gid, _gat, _gcl, _fbp, fr, _pk_");

		# Keep necessary WordPress cookies
		# Not needed, because I earlier gave return(pass) for backend
		cookie.keep("wordpress_logged_in_,wp-settings,wp-settings-time,_wp_session,resetpass");

		set req.http.cookie = cookie.get_string();

		# Don' let empty cookies travel any further
		if (req.http.cookie == "") {
			unset req.http.cookie;
		}
	}

	## Everything what a WordPress needs


        if (req.http.Upgrade ~ "(?i)websocket") {
        	std.log(">> DEBUG: return(pioe) due to websocket: " + req.http.Ugrade );
	        return(pipe);
        } 

        if (req.http.Cache-Control ~ "no-cache" && (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ whitelist)) {
		std.log(">> DEBUG: hash_always_miss due to admin");
                set req.hash_always_miss = true;
        }

    if (
        req.method == "POST" ||
        req.method == "PUT" ||
        req.method == "PATCH" ||
        req.method == "DELETE"
    ) {
        std.log(">> DEBUG: return(pass) due to method: " + req.method);
        return (pass);
    }

    if (req.http.Cookie ~ "wordpress_") {
        std.log(">> DEBUG: return(pass) due to wordpress_ cookie");
        return (pass);
    }

    if (req.http.Cookie ~ "comment_") {
        std.log(">> DEBUG: return(pass) due to comment_ cookie");
        return (pass);
    }

    if (req.http.X-Requested-With == "XMLHttpRequest") {
        std.log(">> DEBUG: return(pass) due to XMLHttpRequest");
        return (pass);
    }

    if (req.url ~ "wp-(login|admin)") {
        std.log(">> DEBUG: return(pass) due to wp-login/wp-admin URL");
        return (pass);
    }

    if (req.url ~ "preview=true") {
        std.log(">> DEBUG: return(pass) due to preview=true in URL");
        return (pass);
    }

        if (req.url ~ "(signup|activate|mail|logout)") {
		std.log(">> DEBUG: return(pass) due to wp URL");
                return(pass);
        }

        if (req.url ~ "/mu-.*") {
		std.log(">> DEBUG: return(pass) due to mu-plugin");
                return(pass);
        }
		
	if (req.url ~ "adsbygoogle") {
		std.log(">> DEBUG: return(pass) due to Adsense");
		return(pass);
	}

	if (req.url ~ "^/wp-json/(activitypub|friends)/" || req.url ~ "^/api/(v1|v2)/" || req.url ~ "^/(nodeinfo|webfinger)" || req.url ~ "^/.well-known/") {
                std.log(">> DEBUG: return(pass) due to Fediverse");
		return(pass);
        }

        # WordPress
	if (req.url ~ "/wp-json/wp/") {
    if (req.http.Cookie ~ "wordpress_logged_in") {
        std.log(">> DEBUG: return(pass) due to REST API");
        return(pass);
    }
    return(synth(403, "Unauthorized request"));
}

    std.log(">> DEBUG: passed all pass conditions");

	## Normalize the query arguments.
        # I'm excluding admin, because otherwise it will cause issues.
        # If std.querysort is any earlier it will break things, like giving error 500 when logging out.
        # Every other VCL examples use this really early, but those are really aged tips and 
        # I'm not so sure if those are actually ever tested in production.
	# Done after all passes and before the first hash.
	if (req.url !~ "^/wp-(admin|login)" && req.url !~ "/logout") {
		set req.url = std.querysort(req.url);
	}

	## Ajax-requests: only for visitors
	# This is hazy. if there is nonce, it is personal and should not cache.
	# Commented until I'm sure what to do. And do I have such ones in use at all?
	# Basically everyone I found from logs were by me or bots. And I don't serve bots.
	#if (req.url ~ "admin-ajax\.php" && req.http.cookie !~ "wordpress_logged_in") {
	#	return(hash);
	#}

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
	# Needed because of all return jumps.
	return(hash);

# End of this one	
} 


##############vcl_pipe################
#
sub vcl_pipe {

	## Whole vcl_pipe
	# include/piped.vcl
	call pipeit;

	## The end of the road
}


################vcl_pass################
#
sub vcl_pass {

	## Whole vcl_pass
	# include/passed.vcl
	call passit;

}


################vcl_hash##################
#
sub vcl_hash {

	## Whole vcl_pass
	# include include/hashed.vcl
	call hashit;

	## The end

	# HEADS UP!
	# Allowing lookup will bypass in-build rules, and then you MUST hash host, server and url.
	# If you not, your cache will be totally mess.
#	return(lookup);
}


###################vcl_hit#########################
#
sub vcl_hit {

	## vcl_hit
	# include/hited.vcl
	call hitit;
	
	## End of the road, Jack
}


###################vcl_miss#########################
#
sub vcl_miss {

	### vcl_miss
	# include/missed.vcl
	call missit;

	## Last call
}


###################vcl_backend_response#############
# This will alter everything what a backend responses back to Varnish
# Affets to what i.e. browsers will do

sub vcl_backend_response {

	## First part
	# include/be_start.vcl
	call be_started;

	## Second part, TTLs
	# include/be_ttl.vcl
	call be_ttled;

	## Third part
	# include/be_end.vcl
	call be_ended;

	## Fourh part, xkey
	call ban-tags;

	## We are at the end
}

#######################vcl_backend_error###############
## Tells what to when backend doesn`t give suitable answers and backend_response can't do anything
## The default action is return(deliver)
## Normally this block isn't visible. I'm using it for grace/errro 503 situation
sub vcl_backend_error {

	# Let's try again because there isn an error
	if (bereq.retries < 1) {
		return(retry);
	}

	# If grace-object is available, we use it
	return(deliver);
# That`s it
}

#######################vcl_deliver#####################
#
sub vcl_deliver {

	## Part I
	# include/delivered.vcl
	call deliverit;

	## Let's add the origin by cors.vcl, if needed
	# ext/cors.vcl
	call cors_deliver;

	## A little bit more security using some headers
	# CSP is done in WordPresses
	# ext/addons/security.vcl
	call sec_headers;
	
	## Some counters and that kind of stuff
	# include/counters.vcl
	call countit;
	
	## Manipulating headers etc.
	# include/showed.vcl
	call showit;

	## Don't show funny stuff to bots
	if (req.http.x-bot == "visitor") {
		# lookup can't be in sub vcl
		set resp.http.Your-IP-Country = std.toupper(req.http.X-Country-Code);
	}

	# That's it
}


#################vcl_purge######################
#
sub vcl_purge {

	## vcl_purge
	# include/purged.vcl
	call purgeit;

# End of vcl_purge
}


##################vcl_synth######################
#
sub vcl_synth {

	## Synth counter
	# not is a sub vcl to get easier site by site setting
	set req.http.x-cache = "synth synth";
	# uncomment the following line to show the information in the response
	# set resp.http.x-cache = req.http.x-cache;
	
	## Must handle cors here too
	call cors;
	
	## Synth errors, real on customs
	# include/erroed.vcl
	call errorit;

	## Googlebot and amp_taxonomy errors
        # created by include/clean_up.vcl
        if (resp.status == 200 && resp.reason == "Not an AMP endpoint.") {
                set resp.http.Content-Type = "text/plain; charset=utf-8";
                set resp.http.X-Robots-Tag = "noindex, nofollow";
        }	

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
