sub oblivion {

	if (req.method == "BAN" || req.method == "PURGE" || req.method == "REFRESH") {
               if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP));
                }
		
		# BAN needs a pattern:
		# curl -X BAN -H "X-Ban-Request:^/contact" "www.example.com"
		# varnishadm ban obj.http.Content-Type ~ ^image/
		if (req.method == "BAN") {
			if(!req.http.x-ban-request) {
				return(synth(400,"Missing x-ban header"));
			}
			ban("req.url ~ " 
			+ req.http.x-ban-request
			+ " && req.http.host == " 
			+ req.http.host);
				# Throw a synthetic page so the request won't go to the backend
				return (synth(200,"Ban added"));
		}
	
		# soft/hard purge
		if (req.method == "PURGE") {
			if (!req.http.xkey-purge) {
				return (synth(400, "Missing xkey-purge header"));
			}
			#if (!req.http.xkey-purge) {
			#	return(hash);
			#}
			return(synth(200, "Purging with xkey"));
		}
		
		# Hit-always-miss - Old content will be updated with fresh one.
		if (req.method == "REFRESH") {
			set req.method = "GET";
			set req.hash_always_miss = true;
		}
	
	# This just an example how to ban objects or purge all when country codes come from backend
	#if (req.method == "PURGE") {
	#	if (!std.ip(req.http.X-Real-IP, "0.0.0.0") ~ whitelist) {
	#		return (synth(405, "Purging not allowed for " + req.http.X-Real-IP));
	#	}
		# Backend gave X-Country-Code to indicate clearing of specific geo-variation
	#	if (req.http.X-Country-Code) {
	#		set req.method = "GET";
	#		set req.hash_always_miss = true;
	#	} else {
			# clear all geo-variants of this page
	#		return (purge);
	#		}
	#	} else {
	#		set req.http.X-Country-Code = country.lookup("country/iso_code", std.ip(req.http.X-Real-IP, "0.0.0.0"));
	#		set req.http.X-Country-Code = std.tolower(req.http.X-Country-Code);    
	#		if (req.http.X-Country-Code !~ "(fi|se)") {
	#			set req.http.X-Country-Code = "fi";
	#	}
	}

}

