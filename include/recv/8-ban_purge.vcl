sub 8-ban_purge {

	if (req.method == "BAN" || req.method == "PURGE" || req.method == "REFRESH") {
               if (req.http.X-Bypass != "true") {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP + " " + req.http.X-Country-Code));
                }
		
		## Soft PURGE
		if (req.method == "PURGE") {
        
			# Using  X-Cache-Tags header
			if (req.http.xkey-purge) {
				ban("obj.http.X-Cache-Tags ~ " + req.http.xkey-purge);
				return(synth(200, "Purged cache-tag: " + req.http.xkey-purge));
			}

			# All other PURGEs
			return(hash);
		}

	}

}
