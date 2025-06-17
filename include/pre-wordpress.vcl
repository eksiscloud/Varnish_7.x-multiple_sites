sub before_wp {

        ## Fix Wordpress visual editor and login issues, must be the first url pass requests and
        #  before cookie monster to work.
        # Backend of Wordpress
        if (req.url ~ "^/wp-(login|admin|cron|comments-post\.php)" || req.url ~ "(preview=true|/login|/lataus|/my-account)") {
                return(pass);
        }

        ## Don't cache logged-in user, password reseting and posts behind password
        if (req.http.Cookie ~ "wordpress_logged_in_" || req.http.Cookie ~ "wp-postpass_" || req.http.Cookie ~ "resetpass") {
                return(pass);
        }

	## Don't cache auth, i.e. if REST API needs it.
	if (req.http.Authorization) {
		return(pass);
	}

}
