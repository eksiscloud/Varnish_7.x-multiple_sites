sub hashit {

	### Everything from vcl_hash

	## Caching per language, that's why we normalized this
	# Because I don't have multilingual, I clean Accept-Language
	# I have one site pure English, but is not Content-Language enough?
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

}

