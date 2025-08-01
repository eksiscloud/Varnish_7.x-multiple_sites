sub vary-5 {

	### vcl_backend_response, fifth part

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
		
# End of this sub
}
