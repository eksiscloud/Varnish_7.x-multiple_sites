sub before_wp {

        ## Page that Monit will ping
        # Change this URL to something that will NEVER be a real URL for the hosted site, it will be effectively inaccessible.
        # 200 OK is same as pass
#       if (req.url == "^/monit-zxcvb") {
#               return(synth(200, "OK"));
#       }
	
	## Fix Wordpress visual editor and login issues, must be the first url pass requests and
        #  before cookie monster to work.
        # Backend of Wordpress
	if (req.url ~ "^/wp-(login|admin|cron|comments-post\.php)" || req.url ~ "(preview=true|/login|/lataus|/my-account)") {
		return(pass);
	}

	## Don't cache logged-in user, password reseting and posts behind password
	# Could be after cookie monster, but let be is safe side bedfore cookies are messed
	if (req.http.Cookie ~ "wordpress_logged_in_" || req.http.Cookie ~ "wp-postpass_" || req.http.Cookie ~ "resetpass") {
		return(pass);
	}

	## Don't cache auth, i.e. if REST API needs it.
	if (req.http.Authorization) {
		return(pass);
	}

}
