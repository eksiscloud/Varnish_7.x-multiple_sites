sub start-1 {

	### vcl_backend_respone, first part

	## Add name of backend in varnishncsa log. The name is shown only if backend responds.
	# You can find slow replying backends (over 3 sec) with that:
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' | awk '$7 > 3 {print}'
	# or
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' -q "Timestamp:Beresp[3] > 3 or Timestamp:Error[3] > 3"
	std.log("backend: " + beresp.backend.name);

	## Let's create a couple helpful tag'ish
	set beresp.http.x-url = bereq.url;
	set beresp.http.x-host = bereq.http.host;
	
	## Will kick in if backend is sick
	if (bereq.url ~ "^/wp-json/" || bereq.url ~ "^/wp-admin/") {
		# no grace for admins
		set beresp.grace = 0s;
	} else {
	        set beresp.grace = 12h;
	}

## The end is here
}
