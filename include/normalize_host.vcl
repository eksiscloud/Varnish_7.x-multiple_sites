sub normalize_host {

	## Just normalizing host names
	# I like to keep triple-w
        
	set req.http.host = regsub(req.http.host,
        "^katiska\.eu$", "www.katiska.eu");
         
	set req.http.host = regsub(req.http.host,
        "^eksis\.one$", "www.eksis.one");

	set req.http.host = regsub(req.http.host,
        "^poochierevival\.info$", "www.poochierevival.info");

# it ends here
}
