sub malicious_url {

	## If has happened earlier, stop here
	# This should never happen, though
	if (req.http.X-Match) {
		return (synth(666, "Previously matched"));
	}
	
	# Every match_* -sub, same idea, different classificatiom
	call match_wp_attack;
	call match_sql_attack;
	call match_config_attack;
	call match_php_attack;
	call match_env_attack;
	call match_other_attack;

# It ends here
}

