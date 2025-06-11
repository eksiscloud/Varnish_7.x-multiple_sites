## Jakke Lehtonen
## 
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.7.1 default.vcl for multiple virtual hosts
## 
## default.vcl is splitted in several sub vcls. Those use includes.  That make updating much more easier
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
# www-domains need normalizing
include "/etc/varnish/include/recv/1-normalize_host.vcl";

# Block using ASN
include "/etc/varnish/include/recv/2-asn_blocklist_start.vcl";
include "/etc/varnish/include/recv/2-1-asn_id.vcl";
include "/etc/varnish/include/recv/asn_blocklist.vcl";

# Let's cleanup first reseting headers etc., lightly
include "/etc/varnish/include/recv/3-clean_up.vcl";

# Pure normalizing and similar, normally done first
include "/etc/varnish/include/recv/4-normalize.vcl";

# Cleaning user-agents
include "/etc/varnish/include/recv/5-user_agents.vcl";
include "/etc/varnish/include/recv/5-1-real_users.vcl";
include "/etc/varnish/include/recv/5-2-probes.vcl";
include "/etc/varnish/include/recv/5-3-nice-bot.vcl";

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

# Something must do before cookies are cleaned
include "/etc/varnish/include/pre-wordpress.vcl";

# Cleaning cookies for WordPress
include "/etc/varnish/include/cookie_monster.vcl";

# Setting up pipe/pass/hash etc. what WordPress wants
include "/etc/varnish/include/wordpress.vcl";

# There is still something to do before leaving vcl_recv
include "/etc/varnish/include/last_ones.vcl";

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
	.port = "8989";
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

	## If the backend is done, we change to emergency mode
	if (!std.healthy(sites)) {
		set req.backend_hint = emergency_nginx;
		return(pipe);
	}

	## All normal and we use this backend
	set req.backend_hint = sites;

	## Normalize hostname to avoid double caching
	# only for www-domains
	call normalize_host-1;

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

	## Forbidden means forbidden
	# Nginx deals with countries and user-agents, but one is left: ASN
	call asn_blocklist_start-2;

	## Few small things as reseting headers  before we start working
	call clean_up-3;

	## Normalizing, part 1
	call normalize-4;

	## Users and bots, so let's normalize user-agent, mostly just for easier reading of varnishlog etc.
        call user_agents-5;
		
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
	# include/ban_purge.vcl
	call ban_purge-8;
	
	## Setup CORS
	# ext/cors.vcl
	call cors;

	## These must, should or could do before cookie monster
	# includes/pre-wordpress.vcl
	call before_wp;

	## The infamous Cookie Monster
	# include/cookie_monster.vcl
	call eat_it;

	## Everything what a WordPress needs
	# include/wordpress.vcl
	call wp;
	#call wordpress_debug;

	## Last things to set up
	# include/last_ones.vcl
	call these_too;

	## 50x raportoinnin debug
	if (req.url ~ "^/test-synth") {
            return (synth(503, "Pakotettu virhe"));
	}

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

    ## Yritetään kerran uudelleen, jos tämä on ensimmäinen virhe
    if (bereq.retries < 1) {
        return (retry);
    }

    ## Jos cachessä on grace  käytettävissä, annetaan se
    return(deliver);

    ## Siirretään 503 error
    return(fail);

# We are ready here
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
