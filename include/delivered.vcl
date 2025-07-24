sub deliverit {

	### vcl_deliver, first part

	## Damn, backend is down (or the request is not allowed; almost same thing)
	if (resp.status == 503) {
		return(restart);
	}
	
	## Knockers with 404 will get synthetic error 666 that leads to real error 666
	if (resp.status == 666) {
		return(synth(666, "Requests not allowed for " + req.url));
	}

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

	## Debug for 403
	#if (resp.status == 403) {
	#	call debug_headers;
	#}

	## Logs short and close to expire TTLs
	if (obj.ttl < 3600s && !obj.uncacheable) {
		std.log("SHORT_TTL_DELIVER: " + req.url +
			" HIT/MISS=" + resp.http.X-Cache +
			" TTL=" + obj.ttl);
	}

	## Logs ttl of the most used images
	if (req.url ~ "(?i)\.(jpeg|jpg|png|webp)(\?.*)?$") {
		std.log("IMAGE-DELIVER: " + req.url +
			" HIT/MISS=" + resp.http.X-Cache +
			" TTL=" + obj.ttl);
	}

	## Logs ttl of MP3s
	if (req.url ~ "\.mp3(\?.*)?$") {
		std.log("MP3-DELIVER: " + req.url +
			" HIT/MISS=" + resp.http.X-Cache +
			" TTL=" + obj.ttl);
	}

	## And now I remove my helpful tag'ish
	# Now something like this works:
	# varnishlog -c -g request -i Req* -i Resp* -I Timestamp:Resp -x ReqAcct -x RespUnset -X "RespHeader:(x|X)-(url|host)" 
	unset resp.http.x-url;
	unset resp.http.x-host;
#	unset resp.http.xkey;

	## Vary to browser
	set resp.http.Vary = "Accept-Encoding";

	## Origin should send to browser
	set resp.http.Vary = resp.http.Vary + ",Origin";

	## Set xkey visible
	if (resp.http.X-Cache-Tags) {
	        set resp.http.X-Cache-Tags = resp.http.X-Cache-Tags;
	}
}
