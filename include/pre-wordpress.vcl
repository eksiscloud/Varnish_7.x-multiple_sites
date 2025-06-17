sub before_wp {


        ## Don't cache logged-in user, password reseting and posts behind password
        if (req.http.Cookie ~ "wordpress_logged_in_" || req.http.Cookie ~ "wp-postpass_" || req.http.Cookie ~ "resetpass") {
                return(pass);
        }

	## Don't cache auth, i.e. if REST API needs it.
	if (req.http.Authorization) {
		return(pass);
	}

}
