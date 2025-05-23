sub missit {

	### Whole vcl_miss

	## Miss counter
	set req.http.x-cache = "miss";

	## ESI
	# I don't know how to handle ESI or do I need it at all
	# ESI is enabled in backend and I don't know what I should put in
	# (object needs ESI processing)
	#if (object needs ESI processing) {
	#	unset req.http.accept-encoding;
	#}

}
