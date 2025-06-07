sub clean_up {

	### Tidying a little bit places before the work starts.

	## Reset hit/miss counter
        unset req.http.x-cache;

	## Just to on safe side, if there is i.e. return(pass/restart) that comes from a situation that can mess things
	unset req.http.X-Saved-Origin;

	## Googlebot is flooding with this and filling logs. Now it can't reach the backend
	# I'm doing this in Nginx and not logging.
	# This helps server wide and returns 410, if wanted:
	# if ($arg_taxonomy ~* "^(amp_validation_error|knowledgebase_tag|.*_error)$") {
	# return 410 "Gone. This taxonomy never existed.\n";
	# }
	if (req.url ~ "taxonomy=") {
		return(synth(811, "Gone. This taxonomy never existed.\n")); # synth 410 only for this purpose
	}

# the end
}
