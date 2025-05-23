sub oblivion {

	if (req.method == "BAN" || req.method == "PURGE" || req.method == "REFRESH") {
               if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP));
                }
		
		## Soft PURGE
		if (req.method == "PURGE") {
        
			# Using  X-Cache-Tags header
			if (req.http.xkey-purge) {
				ban("obj.http.X-Cache-Tags ~ " + req.http.xkey-purge);
				return(synth(200, "Purged cache-tag: " + req.http.xkey-purge));
			}

			# Example: audio/images using url
			if (req.url ~ "^/wp-content/uploads/audio/" || req.url ~ "^/wp-content/uploads/images/") {
				ban("obj.url ~ ^" + req.url);
				return(synth(200, "Purged URL match: " + req.url));
			}

			# All other PURGEs
			return(hash);
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
