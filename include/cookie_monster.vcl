sub eat_it {

	## Cookie monster: Keeping needed cookies and deleting rest.
	if (req.http.cookie) {
		cookie.parse(req.http.cookie);

		# Remove analytics and follower cookies
		cookie.delete("__utm, _ga, _gid, _gat, _gcl, _fbp, fr, _pk_");

		# Keep necessary WordPress cookies
		# Not needed, because I earlier gave return(pass) for backend
		cookie.keep("wordpress_logged_in_,wp-settings,wp-settings-time,_wp_session,resetpass");

		set req.http.cookie = cookie.get_string();

		# Don' let empty cookies travel any further
		if (req.http.cookie == "") {
			unset req.http.cookie;
		}
	}

}
