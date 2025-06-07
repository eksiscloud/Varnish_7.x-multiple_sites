sub oblivion {

	if (req.method == "BAN" || req.method == "PURGE" || req.method == "REFRESH") {
               if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP));
                }
		
		## Soft PURGE
		if (req.method == "PURGE") {
        

			# Example: audio/images using url
			if (req.url ~ "^/wp-content/uploads/audio/" || req.url ~ "^/wp-content/uploads/images/") {
				ban("obj.url ~ ^" + req.url);
				return(synth(200, "Purged URL match: " + req.url));
			}

			# All other PURGEs
			return(hash);
		}

	}

# the end of this stub
}
