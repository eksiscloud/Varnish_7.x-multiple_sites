## Jakke Lehtonen
## 
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.1.1 default.vcl for multiple virtual hosts
## 
## This works as a standalone VCL for one WordPress host
##
## Known issues:
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
import geoip2;		# Load the GeoIP2 by MaxMind

# from apt install varnish-modules but it needs same Varnish version that repo is delivering
# I compiled, but it was still claiming Varnish was in apt-given version, even it was newer.
# So I gave up with newer ones.
#import accept;		# Fix Accept-Language
#import xkey;		# another way to ban

# Banning by ASN (uses geoip-VMOD)
include "/etc/varnish/ext/asn.vcl";

# Human's user agent
include "/etc/varnish/ext/user-ua.vcl";

# Tools and libraries
include "/etc/varnish/ext/probes.vcl";

# Bots with purpose
include "/etc/varnish/ext/nice-bot.vcl";

# Manipulating some urls
include "/etc/varnish/ext/manipulate.vcl";

# Centralized way to handle TTLs
#include "/etc/varnish/ext/cache-ttl.vcl";

# CORS can be handful, so let's give own VCL
include "/etc/varnish/ext/cors.vcl";

## Probes are watching if backends are healthy
## You can check if a backend is  healthy or sick:
## varnishadm -S /etc/varnish/secret -T localhost:6082 backend.list

probe sondi {
    #.url = "/index.html";  # or you can use just an url
	# you must have installed libwww-perl:
    .request =
      "HEAD / HTTP/1.1"
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

## ACLs: I can't use client.ip because it is always 127.0.0.1 by Nginx (or any proxy like Apache2)
# Instead client.ip it has to be like std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist
# Heads up! ACL must be in use, if uncommented.
 
# This can do almost everything
acl whitelist {
	"localhost";
	"127.0.0.1";
	"157.180.74.208";
	"85.76.112.42";
}

# All of filtering isn't that easy to do using country, ISP, ASN or user agent. So let's use reverse DNS. Filtering is done at asn.vcl.
# These are mostly API-services that make theirs business passing the origin service.
# Quite many hate hot linking and frames because that is one kind of stealing. These, as SEO-sevices, do exacly same.
# Reverse DNS is done only at starting Varnish, not when reloading. Same can be done using dig or similar and using IP/IPs here.
acl forbidden {
	"printfriendly.com";
}

#################### vcl_init ##################
# Called when VCL is loaded, before any requests pass through it. Typically used to initialize VMODs.
# You have to define server at backend definition too.

sub vcl_init {
	
	## GeoIP
	new country = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-Country.mmdb");
	new city = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-City.mmdb");
	new asn = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-ASN.mmdb");
	
	## Accept-Language
	## Diffent caching for languages. I don't have multilingual sites, though.
	#new lang = accept.rule("fi");
	#lang.add("sv");
	#lang.add("en");
	
# The end of init
}


############### vcl_recv #################
## We should have here only statments without return(...)
## because such jumps to buildin.vcl passing everything in all.common.vcl and hosts' vcl
## The solution has explained here: https://www.getpagespeed.com/server-setup/varnish/varnish-virtual-hosts

sub vcl_recv {
	
	set req.backend_hint = sites;

	## Normalize hostname to avoid double caching
	# I like to keep triple-w
	set req.http.host = regsub(req.http.host,
	"^katiska\.eu$", "www.katiska.eu");
	
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

	## GeoIP-blocking
	# 1st: GeoIP and normalizing country codes to lower case, 
	# because remembering to use capital letters is just too hard
	set req.http.X-Country-Code = country.lookup("country/iso_code", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);
	
	# 2nd: Actual blocking: (earlier I did geo-blocking in iptables, but this is much easier way)
	# I'll ban or stop a country only after several tries, it is not a decision made easily 
	# (well... it is actually)
	# Heads up: Cloudflare and other big CDNs can route traffic through really strange datacenters 
	# like from Turkey to Finland via Senegal
	if (req.http.X-Country-Code ~ 
		"(bd|bg|by|cn|cr|cz|ec|fr|ro|rs|ru|sy|hk|id|in|iq|ir|kr|ly|my|ph|pl|sc|sg|tr|tw|ua|vn)"
	) {
		std.log("banned country: " + req.http.X-Country-Code);
		return(synth(403, "Forbidden country: " + std.toupper(req.http.X-Country-Code)));
	}
	
	# Quite often russians lie origin country, but are declaring russian as language
	if (req.http.Accept-Language ~
                "(ru_RU|ru-RU|ru$)"
	) {
                std.log("banned language: " + req.http.Accept-Language);
		return(synth(403, "Unsupported language: " + req.http.Accept-Language));
	}

	## I can block service provider too using geoip-VMOD.
	# 1st: Finding out and normalizing ASN
	set req.http.x-asn = asn.lookup("autonomous_system_organization", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	set req.http.x-asn = std.tolower(req.http.x-asn);
	
	# 2nd: Actual blocking: (customers from these are knocking security holes etc. way too often)
	# Finding out ASN from whois-data isn't so straight forwarded
	# You can find it out using ASN lookup like https://hackertarget.com/as-ip-lookup/
	# I had to pass IPs of WP Rocket even they are using banned ASN; I don't use WP Rocket anymore, though
	# I need this for trash, that are coming from countries I can't ban.
	# ext/asn.vcl
	call asn_name;

	## Redirecting http/80 to https/443
        # This could, and perhaps should, do in Nginx, but certbot likes this better
        if ((req.http.X-Forwarded-Proto && req.http.X-Forwarded-Proto != "https") ||
        (req.http.Scheme && req.http.Scheme != "https")) {
                return(synth(750));
        }

	## It will terminate badly formed requests
        ## Build-in rule. But works only if there isn't return(...) that forces jump away
        if (!req.http.host && req.esi_level == 0 && req.proto ~ "^(?i)HTTP/1.1") {
                # In HTTP/1.1, Host is required.
                return (synth(400));
        }

	# if there is PROXY in use
	# Used with Hitch or similar dumb ones 
	#elseif (!req.http.X-Forwarded-Proto && !req.http.Scheme && !proxy.is_ssl()) {
	#	return(synth(750));
	#}
	
	## Let's clean up Proxy.
	# It comes from dumb TSL-proxies like Hitch
	# This is old security measurement too
	unset req.http.Proxy;

	## Normalize the header, remove the port (in case you're testing this on various TCP ports)
	set req.http.host = std.tolower(req.http.host);
	set req.http.host = regsub(req.http.host, ":[0-9]+", "");
	
	## Normalizing language
	# Everybody will get fi. Should I remove it totally?
	#set req.http.Accept-Language = lang.filter(req.http.Accept-Language);

	## User and bots, so let's normalize UA, mostly just for easier reading of varnishtop
        # These should be real users, but some aren't
        # ext/user-ua.vcl
        call real_users;
	
	# Technical probes, so normalize UA using probes.vcl
	# These are useful and I want to know if backend is working etc.
	# ext/probes.vcl
	if (req.http.x-bot != "visitor") {
		call tech_things;
	}

	# These are nice bots, and I'm normalizing using nice-bot.vcl and using just one UA
	# ext/nice-bot.vcl
	if (req.http.x-bot != "(visitor|tech)") {
		call cute_bot_allowance;
	}
	
	# If a user agent isn't identified as user or a bot, its type is unknown.
	# We must presume it is a visitor. 
	# There is big chance it is bot/scraper, but we have false identifications anyway. 
	if (!req.http.x-user-agent) {
                set req.http.x-user-agent = "Unlisted: " + req.http.User-Agent;
		set req.http.x-bot = "visitor";
        }

	## Let's tune up a bit behavior for healthy backends: Cap grace to 12 hours
	if (std.healthy(req.backend_hint)) {
		set req.grace = 43200s;
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

	## Remove the Google Analytics added parameters, useless for backend
	if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=") {
		set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
		set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
		set req.url = regsub(req.url, "\?&", "?");
		set req.url = regsub(req.url, "\?$", "");
	}
		
	## URL changes by ext/manipulate.vcl, mostly fixed search strings
	if (req.http.x-bot == "visitor") {
		call new_direction;
	}
	
	## Save Origin (for CORS) in a custom header and remove Origin from the request 
	## so that backend doesn’t add CORS headers.
	set req.http.X-Saved-Origin = req.http.Origin;
	unset req.http.Origin;

	## Send Surrogate-Capability headers to announce ESI support to backend
	# I don't understand at all what this is doing
	set req.http.Surrogate-Capability = "key=ESI/1.0";
	
	## Who can do BAN, PURGE and REFRESH and how
	# Remember to use capitals when doing, size matters...
	
	if (req.method == "BAN|PURGE|REFRESH") {
               if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP));
		}
		
		# BAN needs a pattern:
		# curl -X BAN -H "X-Ban-Request:^/contact" "www.example.com"
		# varnishadm ban obj.http.Content-Type ~ ^image/
		if (req.method == "BAN") {
			if(!req.http.x-ban-request) {
				return(synth(400,"Missing x-ban header"));
			}
			ban("req.url ~ " 
			+ req.http.x-ban-request
			+ " && req.http.host == " 
			+ req.http.host);
				# Throw a synthetic page so the request won't go to the backend
				return (synth(200,"Ban added"));
		}
	
		# soft/hard purge
#		if (req.method == "PURGE") {
#			if(!req.http.x-xkey-purge) {
#				return(hash);
#			}
#			set req.http.x-purges = xkey.purge(req.http.x-xkey-purge);
#			if (std.integer(req.http.x-purges,0) != 0) {
#				return(synth(200, req.http.x-purges + " objects purged"));
#			} else {
#				return(synth(404, "Key not found"));
#			}
#		}
		
		# Hit-always-miss - Old content will be updated with fresh one.
		if (req.method == "REFRESH") {
			set req.method = "GET";
			set req.hash_always_miss = true;
		}
	}
	
	# This just an example how to ban objects or purge all when country codes come from backend
	#if (req.method == "PURGE") {
	#	if (!std.ip(req.http.X-Real-IP, "0.0.0.0") ~ whitelist) {
	#		return (synth(405, "Purging not allowed for " + req.http.X-Real-IP));
	#	}
		# Backend gave X-Country-Code to indicate clearing of specific geo-variation
	#	if (req.http.X-Country-Code) {
	#		set req.method = "GET";
	#		set req.hash_always_miss = true;
	#	} else {
			# clear all geo-variants of this page
	#		return (purge);
	#		}
	#	} else {
	#		set req.http.X-Country-Code = country.lookup("country/iso_code", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	#		set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);    
	#		if (req.http.X-Country-Code !~ "(fi|se)") {
	#			set req.http.X-Country-Code = "fi";
	#	}
	#}
	
	## Only deal with "normal" types
	# In-build rules. Those aren't needed, unless return(...) forces skip it.
	# Heads up! BAN/PURGE/REFRESH must be done before this or declared here. Unless those don't work when purging or banning.
	if (req.method != "GET" &&
	req.method != "HEAD" &&
	req.method != "PUT" &&
	req.method != "POST" &&
	req.method != "TRACE" &&
	req.method != "OPTIONS" &&
	req.method != "PATCH" &&
	req.method != "DELETE"
	) {
	# Non-RFC2616 or CONNECT which is weird.
	# Why send the packet upstream, while the visitor is using a non-valid HTTP method?
		return(synth(405, "Non-valid HTTP method!"));
	}
	
	## Only GET and HEAD are cacheable methods AFAIK
        # In-build rule too
        if (req.method != "GET" && req.method != "HEAD") {
                return(pass);
        }

	## Auth requests shall be passed. 
	# Must be before cookie monster, unless Wordpress frontend doesn' know logged in user
        # In-build rule.
        if (req.http.Authorization || req.http.Cookie) {
                return(pass);
        }

	## admin-ajax can be a little bit faster, sometimes, but only if GET
        # This must be before passing wp-admin
        if (req.url ~ "admin-ajax.php" && req.http.cookie !~ "wordpress_logged_in" ) {
               return(hash);
        }

	## Fix Wordpress visual editor and login issues, must be the first url pass requests and
	#  before cookie monster to work.
        # Backend of Wordpress
        if (req.url ~ "/wp-(login|admin|my-account|comments-post.php|cron)" || req.url ~ "/(login|lataus)" || req.url ~ "preview=true") {
                return(pass);
        }

	## Keeping needed cookies and deleting rest.
	# You don't need to hash with every cookie. You can do something like this too:
	# sub vcl_hash {
	#	hash_data(cookie.get("language"));
	# }
	cookie.parse(req.http.cookie);
	# I'm deleting test_cookie because 'wordpress_' acts like wildcard, I reckon
	# But why _pk_ cookies passes?
	cookie.delete("wordpress_test_Cookie,_pk_");
	cookie.keep("wordpress_,wp-settings,_wp-session,wordpress_logged_in_,resetpass,woocommerce_cart_hash,woocommerce_items_in_cart,wp_woocommerce_session_");
	set req.http.cookie = cookie.get_string();

	# Don' let empty cookies travel any further
	if (req.http.cookie == "") {
		unset req.http.cookie;
	}

	## Do not cache AJAX requests.
	if (req.http.X-Requested-With == "XMLHttpRequest") {
		return(pass);
	}

	## Don't cache logged-in user, password reseting and posts behind password
        # Frontend of Wordpress
        if (req.http.cookie ~ "(wordpress_logged_in|resetpass|postpass)") {
                return(pass);
        }
	
	## Enable smart refreshing, aka. ctrl+F5 will flush that page
	# Remember your header Cache-Control must be set something else than no-cache
	# Otherwise everything will miss
	if (req.http.Cache-Control ~ "no-cache" && (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ whitelist)) {
		set req.hash_always_miss = true;
	}
	
	## Page that Monit will ping
	# Change this URL to something that will NEVER be a real URL for the hosted site, it will be effectively inaccessible.
	# 200 OK is same as pass
#	if (req.url == "^/monit-zxcvb") {
#		return(synth(200, "OK"));
#	}
	
	## Adsense incomings are lower when Varnish is on, trying to solve out this
	# is it because of caching or CSP-rules?
	if (req.url ~ "adsbygoogle") {
		return(pass);
	}

	## Implementing websocket support
	if (req.http.Upgrade ~ "(?i)websocket") {
		return(pipe);
	}

	## Cache warmup
	# wget --spider -o wget.log -e robots=off -r -l 5 -p -S -T3 --header="X-Bypass-Cache: 1" --header="User-Agent:CacheWarmer" -H --domains=example.com --show-progress www.example.com
	# It saves a lot of directories, so think where you are before launching it... A protip: /tmp
	if (req.http.X-Bypass-Cache == "1" && req.http.User-Agent == "CacheWarmer") {
		return(pass);
	}
	
	## Large static files are delivered directly to the end-user without waiting for Varnish to fully read the file first.
	# The job will be done at vcl_backend_response
	# But is this really needed nowadays?
	if (req.url ~ "^[^?]*\.(avi|mkv|mov|mp3|mp4|mpeg|mpg|ogg|ogm|wav)(\?.*)?$") {
		unset req.http.cookie;
		return(hash);
	}

	## Cache all static files by Removing all Cookies for static files
	# Remember, do you really need to cache static files that don't cause load? Only if you have memory left.
	if (req.url ~ "^[^?]*\.(7z|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gz|ico|js|otf|pdf|ppt|pptx|rtf|svg|swf|tar|tbz|tgz|ttf|txt|txz|webm|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
		unset req.http.cookie;
		return(hash);
	}
		
	## Some devices, mainly from Apple, send urls ending /null
	if (req.url ~ "/null$") {
		set req.url = regsub(req.url, "/null", "/");
	}
	
	## REST API 
	# I don't want to fill RAM for benefits of bots.
	
	# Mastodon/ActivityPub
	if (req.url ~ "^/wp-json/(activitypub|friends)/") {
		return(pass);
	} 
	
	# WordPress
	if ( !req.http.Cookie ~ "wordpress_logged_in" && req.url ~ "/wp-json/wp/v2/" ) {
		return(synth(403, "Unauthorized request"));
	}

#	if (req.url ~ "^/wp-json/") {
#		return(pass);
#	}

	## Don't cache wordpress related pages
	if (req.url ~ "(signup|activate|mail|logout)") {
		return(pass);
	}

	## Must Use plugins I reckon
	if (req.url ~ "/mu-.*") {
		return(pass);
	}

	## Hit everything else
	# I'm dealing with both, Wordpress and Woocommerce, here even I have Woocommerce spesific vcl too.
	# Again, 'tuote' is product in finnish
	if (req.url !~ "(wp-(login.php|cron.php|admin|comment)|login|cart|my-account|wc-api|checkout|addons|loggedout|lost-password|tuote)") {
		unset req.http.cookie;
	}

	## Normalize the query arguments.
        # Perhaps wp-admin etc should be excluded?
        # If std.querysort is any earlier it will break things, like giving error 500 when logging out.
	# Every other VCL examples use this really early, but those are really aged tips and 
	# I'm not so sure if those are actually ever tested in production.
	set req.url = std.querysort(req.url);

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

	## Cache all others requests if they reach this point.
	return(hash);

# End of this one	
} 


##############vcl_pipe################
#
sub vcl_pipe {

	## Implementing websocket support
	if (req.http.upgrade) {
		set bereq.http.upgrade = req.http.upgrade;
		set bereq.http.connection = req.http.connection;
	}

	## The end of the road
}


################vcl_pass################
#
sub vcl_pass {


}


################vcl_hash##################
#
sub vcl_hash {

	## Caching per language, that's why we normalized this
	# Because I don't have multilingual, everything goes under "fi"
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

	## The end

	# HEADS UP!
	# Allowing lookup will bypass in-build rules, and then you MUST hash host, server and url.
	# If you not, your cache will be totally mess.
#	return(lookup);
}


###################vcl_hit#########################
#
sub vcl_hit {

	if (req.method == "PURGE") {
		
		## Hard purge sets all values (TTL, grace, keep) to 0 sec (plus build-in TTL I reckon)
#		set req.http.purged = purge.hard();

#		if (req.http.purged == "0") {
#			return(synth(404));
#		} else {
#			return(synth(200, req.http.purged + " items purged."));
#		}
	
		## Soft purge: zero values do same as hard purge
		set req.http.purged = purge.soft(
			std.duration(req.http.ttl,0s),
			std.duration(req.http.grace,120s),
			std.duration(req.http.keep,0s)
		);
	
		if (req.http.purged == "0") {
			return (synth(404));
		} else {
			return (synth(200, req.http.purged + " items purged."));
		}
	
	}
	
	## End of the road, Jack
}


###################vcl_miss#########################
#
sub vcl_miss {

	## ESI
	# I don't know how to handle ESI or do I need it at all
	# ESI is enabled in backend and I don't know what I should put in
	# (object needs ESI processing)
	#if (object needs ESI processing) {
	#	unset req.http.accept-encoding;
	#}

	if (req.method == "PURGE") {
		
		## Hard purge sets all values (TTL, grace, keep) to 0 sec (plus build-in T>
#               set req.http.purged = purge.hard();

#               if (req.http.purged == "0") {
#                       return(synth(404));
#               } else {
#                       return(synth(200, req.http.purged + " items purged."));
#               }
        
                ## Soft purge: zero values do same as hard purge
                set req.http.purged = purge.soft(
                        std.duration(req.http.ttl,0s),
                        std.duration(req.http.grace,120s),
                        std.duration(req.http.keep,0s)
                );
        
                if (req.http.purged == "0") {
                        return (synth(404));
                } else {
                        return (synth(200, req.http.purged + " items purged."));
                }

	}

	## Last call
}


###################vcl_backend_response#############
# This will alter everything what a backend responses back to Varnish
#
sub vcl_backend_response {

	## Add name of backend in varnishncsa log
	# You can find slow replying backends (over 3 sec) with that:
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' | awk '$7 > 3 {print}'
	# or
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' -q "Timestamp:Beresp[3] > 3 or Timestamp:Error[3] > 3"
	std.log("backend: " + beresp.backend.name);

	## Let's create a couple helpful tag'ish
	set beresp.http.x-url = bereq.url;
	set beresp.http.x-host = bereq.http.host;
	
	## Will kick in if backend is sick
        # Why using grace instead keep? IDK.
        set beresp.grace = 12h;

	## Backend is down, stop caching but using ttl+grace instead
	if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {
		if (bereq.is_bgfetch) {
			return(abandon);
		}
		set beresp.uncacheable = true;
	}
	
	## Give relative short TTL to private ones
	# Is there any point for this? Quite many plugins set private and that's why I clean cache-control later.
	#if (beresp.http.cache-control ~ "private") {
        #        set beresp.uncacheable = true;
	#	set beresp.ttl = 7200s; # 2h
	#}


	## ESI is enabled and now in use if needed
	# except... I didn't configured this on MISS
	if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
		unset beresp.http.Surrogate-Control;
		set beresp.do_esi = true;
	}

	###  How long Varnish will keep objects aka. TTL -->

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

	##### <-- The end of setting TTLs

	## Let' build Vary
        # first cleaning it, because we don't care what backend wants.
        unset beresp.http.Vary;
        
        # I normalize Accept-Language, so it can be in vary
	#set beresp.http.Vary = "Accept-Language";
        
	# Accept-Encoding could be in Vary, because it changes content
	# But it is handled internally by Varnish.
	set beresp.http.Vary = beresp.http.Vary + ",Accept-Encoding";
	
	# User-Agent was sended to backend, but removing it from Vary prevents Varnish to use it for caching
	# Is this really needed? I removed UA and backend doesn't set it up, but uses what it gets from http.req
        if (beresp.http.Vary ~ "User-Agent") {
                set beresp.http.Vary = regsuball(beresp.http.Vary, ",? *User-Agent *", "");
                set beresp.http.Vary = regsub(beresp.http.Vary, "^, *", "");
                if (beresp.http.Vary == "") {
                        unset beresp.http.Vary;
                }
        }
		
	## Same thing here as in vcl_miss 
	## No clue what to put as object 
	#if (object needs ESI processing) {
	#	set beresp.do_esi = true;
	#	set beresp.do_gzip = true;
	#}
	
	## Unset cookies except for Wordpress pages 
	# Heads up: some sites may need to set cookie!
	if (
		bereq.url !~ "(wp-(login|admin)|login|admin-ajax|my-account|addons|logout|resetpass|lost-password)" &&
		bereq.http.cookie !~ "(wordpress_|resetpass|wp-postpass)" &&
		beresp.status != 302 &&
		bereq.method == "GET"
		) { 
		unset beresp.http.set-cookie; 
	}
	
	## Do I really have to tell this again?
	# In-build, not needed. On other hand, it sends uncacheable right away to backend.
	if (bereq.method == "POST") {
		set beresp.uncacheable = true;
		return(deliver);
	}

	## I set X-Trace header, prepending it to X-Trace header received from backend. 
	# Useful for troubleshooting
	#if(beresp.http.x-trace && !beresp.was_304) {
	#	set beresp.http.X-Trace = regsub(server.identity, "^([^.]+),?.*$", "\1")+"->"+regsub(beresp.backend.name, "^(.+)\((?:[0-9]{1,3}\.){3}([0-9]{1,3})\)","\1(\2)")+"->"+beresp.http.X-Trace;
	#}
	#else {
	#	set beresp.http.X-Trace = regsub(server.identity, "^([^.]+),?.*$", "\1")+"->"+regsub(beresp.backend.name, "^(.+)\((?:[0-9]{1,3}\.){3}([0-9]{1,3})\)","\1(\2)");
	#}

	## Unset Accept-Language, if backend gave one. We still want to keep it outside cache.
	unset beresp.http.Accept-Language;

	## Unset the old pragma header
	# Unnecessary filtering 'cos Varnish doesn't care of pragma, but it is ugly in headers
	# AFAIK WordPress doesn't use Pragma, so this is unnecessary here.
	unset beresp.http.Pragma;

	## We are at the end
}


#######################vcl_deliver#####################
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

	## And now I remove my helpful tag'ish
	# Now something like this works:
	# varnishlog -c -g request -i Req* -i Resp* -I Timestamp:Resp -x ReqAcct -x RespUnset -X "RespHeader:(x|X)-(url|host)" 
	unset resp.http.x-url;
	unset resp.http.x-host;

	## Vary to browser
	set resp.http.Vary = "Accept-Encoding";

	## Let's add the origin by cors.vcl. But I'm using * so...
	# ext/cors.vcl
	call cors;
	
	# Origin should send to browser
	set resp.http.Vary = resp.http.Vary + ",Origin";
	
	## Just some unneeded headers showing unneeded data

	# HIT & MISS
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

	## Using ETAG (content based) by backend is more accurate than Last-Modified (time based), 
	# but I want to get last-modified because I'm curious, even curiosity kills the cat
	set resp.http.Modified = resp.http.Last-Modified;
	unset resp.http.Last-Modified;
	
	## Just to be sure who is seeing what
	if (req.http.x-bot) {
		set resp.http.debug = req.http.x-bot;
	}
	
	## Expires and Pragma  are unneeded because cache-control overrides it
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
	## Custom headers, not so serious thing 
	set resp.http.Your-Agent = req.http.User-Agent;
	set resp.http.Your-IP = req.http.X-Real-IP;
	set resp.http.Your-Language = req.http.Accept-Language;

	## Don't show funny stuff to bots
	if (req.http.x-bot == "visitor") {
		# lookup can't be in sub vcl
		set resp.http.Your-IP-Country = country.lookup("country/names/en", std.ip(req.http.X-Real-IP, "0.0.0.0")) + "/" + std.toupper(req.http.X-Country-Code);
		set resp.http.Your-IP-City = city.lookup("city/names/en", std.ip(req.http.X-Real-IP, "0.0.0.0"));
		set resp.http.Your-IP-GPS = city.lookup("location/latitude", std.ip(req.http.X-Real-IP, "0.0.0.0")) + " " + city.lookup("location/longitude", std.ip(req.http.X-Real-IP, "0.0.0.0"));
		set resp.http.Your-IP-ASN = asn.lookup("autonomous_system_organization", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	}

	# That's it
}


#################vcl_purge######################
#
sub vcl_purge {

#	return (synth(200, "Purged"));

	## Only handle actual PURGE HTTP methods, everything else is discarded
	if (req.method == "PURGE") {
		# restart request
		set req.http.X-Purge = "Yes";
		# let's get right away fresh stuff
		set req.method = "GET";
		return (restart);
	}

# End of vcl_purge
}


##################vcl_synth######################
#
sub vcl_synth {

	call cors;
	
	### Custom errors
		
	## Bad request error 400
	if (resp.status == 400) {
                set resp.status = 400;
                set resp.http.Content-Type = "text/html; charset=utf-8";
                set resp.http.Retry-After = "5";
                synthetic( {"<!DOCTYPE html>
                <html>
                        <head>
                                <title>Error "} + resp.status + " " + resp.reason + {"</title>
                        </head>
                        <body>
                                <h1>Error "} + resp.status + " " + resp.reason + {"</h1>
                                <p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</>
                                <h3>Guru Meditation:</h3>
                                <p>XID: "} + req.xid + {"</p>
                                <hr>
                                <p>Varnish cache server</p>
                        </body>
                </html>
                "} );
                return (deliver);
        }

	## forbidden error 403
	if (resp.status == 403) {
		set resp.status = 403;
		set resp.http.Content-Type = "text/html; charset=utf-8";
		set resp.http.Retry-After = "5";
		synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
		"} );
		unset req.http.connection;
		return (deliver);
	}
	
	## Locked (ASN)
	if (resp.status == 423) {
		set resp.status = 423;
		set resp.http.Content-Type = "text/html; charset=utf-8";
		set resp.http.Retry-After = "5";
		synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
		"} );
		unset req.http.connection;
		return (deliver);
	}
	
	## Forbidden url
	if (resp.status == 429) {
		set resp.status = 429;
		set resp.http.Content-Type = "text/html; charset=utf-8";
		set resp.http.Retry-After = "5";
		synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
		"} );
		unset req.http.connection;
		return (deliver);
	}
		
	## System is down
	if (resp.status == 503) {
		set resp.status = 503;
		set resp.http.Content-Type = "text/html; charset=utf-8";
		set resp.http.Retry-After = "5";
		synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
		"} );
		return (deliver);
	} 
	
	## robots.txt for those sites that not generate theirs own
	# doesn't work with Wordpress if under construction plugin is on
	if (resp.status == 601) {
		set resp.status = 200;
		set resp.reason = "OK";
		set resp.http.Content-Type = "text/plain; charset=utf8";
		synthetic( {"
		User-agent: *
		Disallow: /
		"} );
		return(deliver);
	}

	## Custom error for banning
	if (resp.status == 666) {
		set resp.status = 666;
		set resp.http.Content-Type = "text/html; charset=utf-8";
		set resp.http.Retry-After = "5";
		synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
		"} );
		unset req.http.connection;
		return (deliver);
	}

	## 301/302 redirects using custom status
	if (resp.status == 701) {
	# We use this special error status 720 to force redirects with 301 (permanent) redirects
	# To use this, call the following from anywhere in vcl_recv: return(synth(701, "http://host/new.html"));
		set resp.http.Location = resp.reason;
		set resp.status = 301;
		set resp.reason = "Moved";
		return(deliver);
	} elseif (resp.status == 702) {
	# And we use error status 721 to force redirects with a 302 (temporary) redirect
	# To use this, call the following from anywhere in vcl_recv: return(synth(702, "http://host/new.html"));
		set resp.http.Location = resp.reason;
		set resp.status = 302;
		set resp.reason = "Moved temporary";
		return(deliver);
	}

	## 80 -> 443 redirect
	if (resp.status == 750) {
                set resp.status = 301;
                set resp.http.location = "https://" + req.http.Host + req.url;
                set resp.reason = "Moved";
                return (deliver);
        }

	## 410 Gone
	if (resp.status == 810) {
		set resp.status = 410;
		set resp.reason = "Gone";
		# If there is custom 410-page
		# but... redirecting doesn't work
		if (req.http.host ~ "www.katiska.eu") {
			set resp.http.Location = "https://www.katiska.eu/error-410-sisalto-on-poistettu/";
			return(deliver);
		} else {
			set resp.http.Content-Type = "text/html; charset=utf-8";
			set resp.http.Retry-After = "5";
			synthetic( {"<!DOCTYPE html>
			<html>
				<head>
					<title>Error "} + resp.status + " " + resp.reason + {"</title>
				</head>
					<body>
						<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
						<p>Sorry, the content you were looking for has deleted. </p>
						<h3>Guru Meditation:</h3>
						<p>XID: "} + req.xid + {"</p>
						<hr>
						<p>Varnish cache server</p>
					</body>
				</html>
			"} );
			return(deliver);
		}
	}

	## all other errors if any
	set resp.http.Content-Type = "text/html; charset=utf-8";
	set resp.http.Retry-After = "5";
	synthetic( {"<!DOCTYPE html>
		<html>
			<head>
				<title>Error "} + resp.status + " " + resp.reason + {"</title>
			</head>
			<body>
				<h1>Error "} + resp.status + " " + resp.reason + {"</h1>
				<p>"} + resp.reason + " from IP " + std.ip(req.http.X-Real-IP, "0.0.0.0") + {"</p>
				<h3>Guru Meditation:</h3>
				<p>XID: "} + req.xid + {"</p>
				<hr>
				<p>Varnish cache server</p>
			</body>
		</html>
	"} );
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
