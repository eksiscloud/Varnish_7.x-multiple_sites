sub user-agents-5 {

	### Central station for tidying user-agents.
	## I could normalize UA, but nowadays I leave is as it is, and adding two x-headers:
	## x-bot and x-user-agent

	## These should be marked as real users, but some aren't
	call real_users-5-1;

	## Technical probes
        # These are useful and I want to know if backend is working etc.
        if (req.http.x-bot != "visitor") {
                call probes-5-2;
        } 

        ## These are nice bots, and I'm normalizing UA a bit
        if (req.http.x-bot !~ "(visitor|tech)$") {
                call nice-bots-5-3;
        }

# That's all folk
}
