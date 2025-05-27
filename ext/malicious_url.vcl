sub is_malicious_url {

	call match_url_attacks;
	
	if (!req.http.X-Match) {
		call match_plugin_attacks;
	}

	if (!req.http.X-Match) {
		call match_query_attacks;
	}

	## If there a match, it generates an error
	if (req.http.X-Match == "1") {
		if (req.http.X-County-Code ~ "fi" || req.http.X-Language ~ "fi") {
			# lesser error for Finns
			return (synth(403, "The site is unreachable"));
		} else {
			# fail2ban for all others
			return (synth(666, "Security issue"));
		}
	}

}
