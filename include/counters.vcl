sub countit {

	## Just some unneeded headers showing unneeded data

	# HIT & MISS
	if (obj.uncacheable) {
		set req.http.x-cache = req.http.x-cache + " uncacheable" ;
	} else {
		set req.http.x-cache = req.http.x-cache + " cached" ;
	}
	# uncomment the following line to show the information in the response
	set resp.http.x-cache = req.http.x-cache;

	if (obj.hits > 0) {
		# I don't fancy boring hit/miss announcements
		set resp.http.You-had-only-one-job = "Success";
	} else {
		set resp.http.You-had-only-one-job = "Phew";
	}

	# Show hit counts (per objecthead)
	# Same here, something like X-total-hits is just boring
	if (obj.hits > 0) {
		set resp.http.Footprint-of-CO2 = (obj.hits) + " metric-tons";
	} else {
		set resp.http.Footprint-of-CO2 = "Greenwash in progress";
	}

}
