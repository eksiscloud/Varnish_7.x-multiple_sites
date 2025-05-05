## Jakke Lehtonen
## 
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.1.1 default.vcl for multiple virtual hosts
## 
## Known issues:
##  - easy to get false bans (googlebot, Bing...) 
##
## Lets's start caching (...and a little bit more)
 
########
 
# Marker to tell the VCL compiler that this VCL has been adapted to the 4.1 format.
vcl 4.1;

# in-build vmod
import std;

# from geoip package, needs separate compiling per Varnish version
import geoip2;		# Load the GeoIP2 by MaxMind

# fake, never-used backend to silence the compiler
backend fake {
	.host = "0:0";
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
	new asn = geoip2.geoip2("/usr/share/GeoIP/GeoLite2-ASN.mmdb");

# The end of init
}


############### vcl_recv #################

sub vcl_recv {
	
	### The work starts here
	###
	###  vcl_recv is main thing and there will happend only normalizing etc, where is no return(...) statements 
	### because those bypasses other VCLs.
	### all-common.vcl is for cookies and similar commmon things for hosts
	### Every domain-VCLs do the rest where return(...) is needed and part of jobs are done using subs, i.e. 'call common.vcl'
	### Exception to rule no-return-statements is everything where the connection will be terminated for good 
	### and anything else is not needed

	## I must clean up some trashes
	# I should not use return(...) statement here because it passes everything, 
	# but I want stop trashes right away so it doesn't matter

	## Just an example how to do geo-blocking by VMOD.
	# 1st: GeoIP and normalizing country codes to lower case, 
	# because remembering to use capital letters is just too hard
	set req.http.X-Country-Code = country.lookup("country/iso_code", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	# I don't like capital letters
	set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);
	
	# 2nd: Actual blocking: (earlier I did geo-blocking in iptables, but this is much easier way)
	# I'll ban or stop a country only after several tries, it is not a decision made easily 
	# (well... it is actually, and Fail2ban will do that) 
	# Heads up: Cloudflare and other big CDNs can route traffic through really strange datacenters 
	# like from Turkey to Finland via Senegal
	if (req.http.X-Country-Code ~ 
		"(bd|bg|by|cn|cr|cz|ec|fr|ro|rs|ru|sy|hk|id|in|iq|ir|kr|ly|my|ph|pl|sc|sg|tr|tw|ua|vn)"
	) {
		std.log("banned country: " + req.http.X-Country-Code);
		return(synth(403, "Forbidden country: " + std.toupper(req.http.X-Country-Code)));
	}
	
	# Quite often russians lie origin country, but are declaring russian as language
	if (req.http.accept-language ~
                "(ru_RU|ru-RU|ru$)"
	) {
                std.log("banned language: " + req.http.accept-language);
		return(synth(403, "Unsupported language: " + req.http.accept-language));
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
	# Heads up: ASN can and quite often will stop more than just one company
	# Just coming from some ASN doesn't be reason to hard banning,
	# but everyone here is knocking too often so I'll keep doors closed
	if (
		   req.http.x-asn ~ "alibaba"						# Alibaba (US) Technology Co., Ltd., US,CN
		|| req.http.x-asn ~ "avast-as-cd"					# Privax LTD, GB etc.
		|| req.http.x-asn ~ "bladeservers"					# LeaseVPS, NL, AU
		|| req.http.x-asn == "cogent-174"					# BlackHOST Ltd., NL
		|| req.http.x-asn ~ "contabo"						# Contabo Inc., US
		|| req.http.x-asn ~ "corporacion dana"				# Computer Company, US but is HN
		|| req.http.x-asn ~ "cypresstel"					# Cypress Telecom Limited, HK
		|| req.http.x-asn ~ "digital energy technologies"	# BG
		|| req.http.x-asn ~ "dreamscape"					# Vodien Internet Solutions Pte Ltd, HK, SG, AU
		|| req.http.x-asn ~ "go-daddy-com-llc"				# GoDaddy.com US (GoDaddy isn't serving any useful services too often)
		|| req.http.x-asn ~ "hvc-as"						# NOC4Hosts Inc., US
		|| req.http.x-asn ~ "idcloudhost"					# PT. SIBER SEKURINDO TEKNOLOGI, PT Cloud Hosting Indonesia, ID
		|| req.http.x-asn ~ "int-network"					# IP Volume inc, SC
		|| req.http.x-asn ~ "internet-it"					# INTERNET IT COMPANY INC, SC
		|| req.http.x-asn ~ "logineltdas"					# Karolio IT paslaugos, LT, US, GB
		|| req.http.x-asn ~ "networksdelmanana"				# Yaroslav Kharitonova, UY via HN from RU
		|| req.http.x-asn == "njix"							# laceibaserver.com, DE, US
		|| req.http.x-asn ~ "online sas"					# IP Pool for Iliad-Entreprises Business Hosting Customers, FR
		|| req.http.x-asn ~ "planeetta-as"					# Planeetta Internet Oy, FI
		|| req.http.x-asn ~ "scalaxy"						# xWEBltd, actually RU using NL and identifying as GB
		|| req.http.x-asn ~ "server-mania"					# B2 Net Solutions Inc., CA
		|| req.http.x-asn ~ "reliablesite"					# Dedires llc, GB from PSE
		|| req.http.x-asn ~ "tefincomhost"					# Packethub S.A., NordVPN, FI, PA
		|| req.http.x-asn ~ "whg-network"					# Web Hosted Group Ltd, GB
		|| req.http.x-asn == "wii"							# Wholesale Internet, Inc US
		) {
			if (req.url !~ "wp-login") {
				std.log("stopped ASN: " + req.http.x-asn);
				return(synth(666, "Forbidden organization: " + std.toupper(req.http.x-asn)));
			} else {
				std.log("banned ASN: " + req.http.x-asn);
				return(synth(423, "Severe security issues: " + std.toupper(req.http.x-asn)));
			}
		}
		
	## These are really bad ones and will be banned by Fail2ban
	# It is just smart move to ban theirs IP-space totally in Fail2ban
	if (
		   req.http.x-asn ~ "adsafe-"						# Integral Ad Science, Inc., US
		|| req.http.x-asn ~ "as_delis"						# Serverion BV, NL
		|| req.http.x-asn ~ "blazingseo"					# DE but is from IL
		|| req.http.x-asn ~ "chinanet-backbone"				# big part of China
		|| req.http.x-asn ~ "chinatelecom"					# a lot and couple more, CN
		|| req.http.x-asn ~ "colocrossing"					# ColoCrossing, US
		|| req.http.x-asn ~ "cyberverse"					# Evocative, Inc./ChunkHost, US
		|| req.http.x-asn ~ "deltahost"						# DeltaHost, NL but actually UA
		|| req.http.x-asn ~ "dreamhost"						# New Dream Network, LLC, US
		|| req.http.x-asn ~ "emerald-onion"					# Emerald Onion/Tor exit, US
		|| req.http.x-asn ~ "iomart"						# IOMART HOSTING LIMITED. GB
		|| req.http.x-asn ~ "ionos"							# 1&1 IONOS Inc., US, SE, DE
		|| req.http.x-asn ~ "leaseweb"						# LeaseWeb Netherlands B.V., NL
		|| req.http.x-asn ~ "m247"							# QuickPacket, LLC, US, m247.com, GB, ES, RO
		|| req.http.x-asn ~ "nocix"							# Nocix, LLC, US
		|| req.http.x-asn ~ "ovh"							# OVH SAS, FR
		|| req.http.x-asn ~ "peenq"							# PEENQ, NL
		|| req.http.x-asn ~ "ponynet"						# FranTech Solutions, US
		|| req.http.x-asn ~ "powerline-as"					# Ngok Fung trading, HK
		|| req.http.x-asn ~ "selectel"						# Starcrecium Limited, CY is actually RU
		|| req.http.x-asn ~ "serverion"						# Serverion BV, NL
		|| req.http.x-asn ~ "squitter-networks"				# ABC Consultancy etc, CINTY EU WEB SOLUTIONS, NL
		|| req.http.x-asn ~ "velianet"						# velia.net Internetdienste GmbH, FR is actually RU
		|| req.http.x-asn ~ "wellnet"						# xWEBltd, NL is really RU
		) {
			std.log("banned ASN: " + req.http.x-asn);
			return(synth(423, "Severe security issues: " + std.toupper(req.http.x-asn)));
		}
		
	## Not ASN but is here anyway: stoping some sites using ACL and reverse DNS:
	if (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ forbidden) {
		return (synth(403, "Access Denied " + req.http.X-Real-IP));
	} 

	## Redirecting http/80 to https/443
        ## This could, and perhaps should, do on Nginx but certbot likes this better
        ## I assume this could be done in default.vcl too but I don't know if
        ## X-Forwarded-Proto would come here then
        if ((req.http.X-Forwarded-Proto && req.http.X-Forwarded-Proto != "https") ||
        (req.http.Scheme && req.http.Scheme != "https")) {
                return(synth(750));
        }

	## It will terminate badly formed requests
        ## Build-in rule, that's why it is commented. But works only if there isn't return(...) that forces jump away
        if (!req.http.host && req.esi_level == 0 && req.proto ~ "^(?i)HTTP/1.1") {
                # In HTTP/1.1, Host is required.
                return (synth(400));
        }

	## Finally we are heading to sites
	if (req.http.host == "www.katiska.eu" || req.http.host == "katiska.eu") {
		return (vcl(katiska));
	} 
	if (req.http.host == "store.katiska.eu") {
		return(vcl(store));
	} 
	if (req.http.host == "selko.katiska.eu") {
		return(vcl(selkokatiska));
	} 
	if (req.http.host == "www.eksis.one" || req.http.host == "eksis.one") {
                return(vcl(eksisone));
        } 
	if (req.http.host == "jagster.eksis.one") {
                return(vcl(jagster));
        } 
	if (req.http.host == "dev.eksis.one") {
                return(vcl(dev));
        } 
	if (req.http.host == "stats.eksis.eu") {
                return(vcl(stats));
	}	
	return (synth(404));
	

## End of this road
}

##############vcl_pipe################
#
sub vcl_pipe {

	## The end of the road
}


################vcl_pass################
#
sub vcl_pass {


}


################vcl_hash##################
#
sub vcl_hash {


	## The end

	# HEADS UP!
	# Allowing lookup will bypass in-build rules, and then you MUST hash host, server and url.
	# If you not, your cache will be totally mess.
#	return(lookup);
}


###################vcl_hit#########################
#
sub vcl_hit {

	## End of the road, Jack
}


###################vcl_miss#########################
#
sub vcl_miss {

	## Last call
}


###################vcl_backend_response#############
# This will alter everything what a backend responses back to Varnish
#
sub vcl_backend_response {

	## We are at the end
}


#######################vcl_deliver#####################
#
sub vcl_deliver {

	# That's it
}


#################vcl_purge######################
#
sub vcl_purge {


# End of vcl_purge
}


##################vcl_synth######################
#
sub vcl_synth {

	### Custom errors
		
	## Bad request error 400
	if (resp.status == 400) {
                set resp.status = 400;
                #synthetic(std.fileread("/etc/varnish/error/503.html"));
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
		#synthetic(std.fileread("/etc/varnish/error/403.html"));
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
		#synthetic(std.fileread("/etc/varnish/error/423.html"));
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
		#synthetic(std.fileread("/etc/varnish/error/429.html"));
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
		#synthetic(std.fileread("/etc/varnish/error/503.html"));
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
		#synthetic(std.fileread("/etc/varnish/error/666.html"));
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

