sub be_ended {

	### vcl_backend_response, third part

	## Let' build Vary
        # first cleaning it, because we don't care what backend wants.
        unset beresp.http.Vary;
        
        # I normalize Accept-Language, so it can be in vary
	#set beresp.http.Vary = "Accept-Language";
        
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
	# In-build, not needed. On other hand, it sends uncacheable right away to user.
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

}
