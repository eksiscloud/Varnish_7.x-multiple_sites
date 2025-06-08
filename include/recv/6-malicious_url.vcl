sub 6-malicious_url {

	# Every match_* -sub, same idea, different classificatiom
	call match_wp_attack;
	call match_sql_attack;
	call match_config_attack;
	call match_php_attack;
	call match_env_attack;
	call match_other_attack;

	## WordPress login
	if (req.url ~ "^/wp-login" &&
	   (req.http.X-Country-Code !~ "fi" ||
	    req.http.Accept-Language !~ "fi")) 
	    {
		return (synth(666, "The site is unreachable"));
	}

	## I have one site using category wordpress
	if (req.http.host !~ "www.eksis.one") {
		if (req.url ~ "^/wordpress") {
			if (
			   req.http.X-Country-Code ~ "fi"
			|| req.http.Accept-Language ~ "fi" 
				) {
				return(synth(403, "The site is unreachable"));
			} else {
				return(synth(666, "The site is unreachable"));
			}
		}
	}

	## Unnecessary requests
	if (req.url ~ "apple-app-site-association") { return(synth(403, "Forbidden")); }
	
	## Why bots are requesting wp-admin/install.php?
	if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist && req.url ~ "/wp-admin/install.php") {
		return(synth(666, "Forbidden request"));
	}

# It ends here
}

