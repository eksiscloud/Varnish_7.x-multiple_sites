sub ban_purge-8 {

	if (req.method == "BAN" || req.method == "PURGE" || req.method == "REFRESH") {
               if (req.http.X-Bypass != "true") {
                       return (synth(405, "Banning/purging not allowed for " + req.http.X-Real-IP + " " + req.http.X-Country-Code));
                }
		
		## Soft PURGE
		if (req.method == "PURGE") {
        
			# Using  X-Cache-Tags header
			if (req.http.xkey-purge) {
				if (req.http.xkey-purge ~ "^url-") {
            				# Hard purge suoraan URL-tagille
                                        xkey.purge(req.http.xkey-purge);
                                        return(synth(200, "Purged by xkey: " + req.http.xkey-purge));
                                 } else {
					ban("obj.http.X-Cache-Tags ~ " + req.http.xkey-purge);
					return(synth(200, "Purged cache-tag: " + req.http.xkey-purge));
				}
			}

			# All other PURGEs
			return(hash);
		}

	}

}
