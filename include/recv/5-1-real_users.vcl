sub 5-1-real_users {

	if (req.http.User-Agent ~ "Android") {
		#set req.http.User-Agent = "Android";
		set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "Android";
	}

	if (req.http.User-Agent ~ "NT 10") {
                #set req.http.User-Agent = "Windows";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "Windows";
        }

	if (req.http.User-Agent ~ "NT 6") {
                #set req.http.User-Agent = "Win/Bot";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "Win/Bot";
        }

	if (req.http.User-Agent ~ "X11") {
                #set req.http.User-Agent = "Linux/Bot";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "Linux/Bot";
        }

	if (req.http.User-Agent ~ "iPhone") {
                #set req.http.User-Agent = "iPhone";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "iPhone";
        }

	if (req.http.User-Agent ~ "iPad") {
                #set req.http.User-Agent = "iPad";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "iPad";
        }

	if (req.http.User-Agent ~ "Macintosh") {
                #set req.http.User-Agent = "Mac";
                set req.http.x-bot = "visitor";
		set req.http.x-user-agent = "Mac/iPad";
        }

}
