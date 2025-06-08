sub 5-2-probes {

	## Local ones
	if (req.http.User-Agent ~ "Matomo") {
		set req.http.User-Agent = "Matomo";
		set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Monit") {                
                set req.http.User-Agent = "Monit";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

	if (req.http.User-Agent ~ "WordPress/") { 
                set req.http.User-Agent = "WordPress";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

	if (req.http.User-Agent == "Varnish Health Probe") { 
		set req.http.x-bot = "tech"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	# KatiskaWarmer will warm up cache, so it has to look like a visitor
        if (req.http.User-Agent == "KatiskaWarmer") {
                if (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ whitelist) {
                        set req.http.x-bot = "visitor";
                        set req.http.x-user-agent = req.http.User-Agent;
                } else {
                        return(synth(666, "False Bot"));
                }
        }

	# Allowed only from whitelisted IP, but no bans by Fail2ban either
	# Works only when user agent has not been changed, so this will stop only easy ones... 
	# guess what, the most are really easy in the meaning those script kiddies are really dumb
	if (req.http.x-bot == "tech") {
                if (req.http.X-Bypass != "true") {
                        return(synth(666, "Forbidden Bot " + req.http.X-Real-IP));
                }
        }

        if (req.http.User-Agent ~ "curl") {
                set req.http.User-Agent = "curl";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

        if (req.http.User-Agent ~ "wget") {
                set req.http.User-Agent = "wget";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

        if (req.http.User-Agent ~ "libwww-perl") {
                set req.http.User-Agent = "libwww-perl";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

        if (req.http.User-Agent ~ "lwp-request") {
                set req.http.User-Agent = "lwp-request";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

        if (req.http.User-Agent ~ "HTTPie") {
                set req.http.User-Agent = "HTTPie";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }

        if (req.http.User-Agent ~ "ruby") {
                set req.http.User-Agent = "ruby";
                set req.http.x-bot = "tech";
		set req.http.x-user-agent = req.http.User-Agent;
        }


        # Apple's way
#       if (req.http.User-Agent ~ "okhttp") {
#               if (req.http.url !~ "apple-touch-icon.png") {
#                       return(synth(666, "Forbidden Bot " + req.http.X-Real-P));
#               } else {
#                       set req.http.x-bot = "tech";
#			set req.http.x-user-agent = req.http.User-Agent;
#               }
#       }

	## For logging
        if (req.http.x-bot == "tech") {
                std.log("BOT_DETECTED IP=" + req.http.X-Real-IP + " " + req.http.X-Country-Code + " User-Agent:" + req.http.User-Agent);
        }

# And here's the end
}
