sub tech_things {

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

	# Allowed only from whitelisted IP, but no bans by Fail2ban either
	# Works only when user agent has not been changed, so this will stop only easy ones... 
	# guess what, the most are really easy in the meaning those script kiddies are really dumb
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

	## Now we shall filtering techs by whitelisted IPs
        if (req.http.x-bot == "tech") {
                if (std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
                        return(synth(666, "Forbidden Bot " + req.http.X-Real-IP));
                }
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

        ## UptimeRobot has access only to some urls; if it tries something else it is not legit one
        if (req.http.User-Agent ~ "UptimeRobot") {
                if (req.url ~ "^/(pong|tietosuojaseloste|latest)") {
                        set req.http.User-Agent = "UptimeRobot";
                        set req.http.x-bot = "tech";
			set req.http.x-user-agent = req.http.User-Agent;
                        return(pass);
                } else {
                        return(synth(666, "False Bot"));
                }
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

	# UA git is allowed only with Gitea
#       if (req.http.User-Agent ~ "git/") {
#               if (req.http.host != "git.eksis.one" && std.ip(req.http.X-Real-IP, "0.0.0.0") !~ whitelist) {
#                        #if (req.http.X-Country-Code ~ "fi" || 
#                       if (req.http.x-language ~ "fi") {
#                               set req.http.x-bot = "bad";
#				set req.http.x-user-agent = req.http.x-bot;
#                               return(synth(403, "Access Denied " + req.http.X-Real-IP));
#                       } else {
#                               set req.http.x-bot = "bad";
#				set req.http.x-user-agent = req.http.x-bot;
#                               return(synth(666, "Forbidden Bot " + req.http.X-Real-IP));
#                       } 
#               } else {
#                       set req.http.x-bot = "tech";
#			set req.http.x-user-agent = req.http.User-Agent;
#               }
#       }

# And here's the end
}
