sub ban-tags {
	
	## Per domain
	
	# www.eksis.one
	if (bereq.http.host == "www.eksis.one") {
		if (bereq.url ~ "^/artikkelit/") { set beresp.http.Xkey = beresp.http.Xkey + " artikkelit"; }
	}



# The end
}
