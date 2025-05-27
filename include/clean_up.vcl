sub clean_up {

	### Tidying a little bit places before the work starts.

	## Just to on safe side, if there is i.e. return(pass/restart) that comes from a situation that can mess things
	unset req.http.X-Saved-Origin;

	## Googlebot is flooding with this and filling logs. Now it can't reach the backend
	# I'm doing this in Nginx and not logging.
	# This helps server wide and returns 410, if wanted:
	# location ~* \?taxonomy=amp_validation_error&term= {
	#    access_log off;
	#    add_header X-Robots-Tag "noindex, nofollow" always;
	#    default_type text/plain;
	#    return 410 "Gone. This taxonomy never existed.\n";
	#}
	if (req.url ~ "taxonomy=amp_validation_error&term=") {
		return (synth(200, "Not an AMP endpoint.\n"));
	}

# the end
}
