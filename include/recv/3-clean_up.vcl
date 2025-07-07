sub clean_up-3 {

	### Tidying a little bit places before the work starts.

	## Reset hit/miss counter
        unset req.http.x-cache;

	## Just to on safe side, if there is i.e. return(pass/restart) that comes from a situation that can mess things
	unset req.http.X-Saved-Origin;

# the end
}
