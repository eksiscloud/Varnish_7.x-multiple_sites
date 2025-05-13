#### Jakke Lehtonen
## https://git.eksis.one/jagster/varnish_7.x
## from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.1.1 emergency.vcl when everything goes to south big time
## but it works only if Varnish is up
##

## Lets's start
 
#################### start ##################
# some really important basics must tell to Varnish
 
## Marker to tell the VCL compiler that this VCL has been adapted to the 4.1 format.
vcl 4.1;

import std;

## Backend tells where a site can be found
backend default {
	.host = "127.0.0.1";
	.port = "8282";
	.max_connections = 5000; 
	.first_byte_timeout = 300s;
	.connect_timeout = 300s;
	.between_bytes_timeout = 300s;
}

# git.eksis.one by Gitea
#backend gitea {
#	.path = "/run/gitea/gitea.sock";
#	#.host = "localhost";
#	#.port = "3000";
#	.first_byte_timeout = 300s;
#	.connect_timeout = 300s;
#	.between_bytes_timeout = 300s;
#}

#################### vcl_init ##################

sub vcl_init {
	
# The end of init
}

############### vcl_recv ######################

sub vcl_recv {

	## Redirecting http/80 to https/443
        if ((req.http.X-Forwarded-Proto && req.http.X-Forwarded-Proto != "https") ||
        (req.http.Scheme && req.http.Scheme != "https")) {
                return(synth(750));
        }
	
	## Normalize the host and remove the port
	set req.http.host = std.tolower(req.http.host);
	set req.http.host = regsub(req.http.host, ":[0-9]+", "");
	
	## Lets tell backends
	
	if (
	req.http.host == "www.katiska.eu" ||
	req.http.host == "www.eksis.one" ||
	req.http.host == "www.poochierevival.info" ||
	req.http.host == "dev.eksis.one" ||
	req.http.host == "jagster.eksis.one" ||
	req.http.host == "selko.katiska.eu" ||
	req.http.host == "www.eksis.eu" ||
	req.http.host == "store.katiska.eu" ||
	req.http.host == "stats.eksis.eu" 
	) {
		set req.backend_hint = default;
	} 
	return(pipe);
	
# That's it. We are ready here.
}

################vcl_synth#################
sub vcl_synth {

	## 80 -> 443 redirect
        if (resp.status == 750) {
                set resp.status = 301;
                set resp.http.location = "https://" + req.http.Host + req.url;
                set resp.reason = "Moved";
                return (deliver);
        }

}
