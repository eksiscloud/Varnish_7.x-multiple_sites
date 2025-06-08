sub 5-user-agents {

	### Central station for tidying user-agents.
	## I could normalize UA, but nowadays I leave is as it is, and adding two x-headers:
	## x-bot and x-user-agent

	## These should be marked as real users, but some aren't
	call 5-1-real_users.vcl;

	## Technical probes
        # These are useful and I want to know if backend is working etc.
        if (req.http.x-bot != "visitor") {
                5-2-call probes;
        } 

        ## These are nice bots, and I'm normalizing UA a bit
        if (req.http.x-bot !~ "(visitor|tech)$") {
                call 5-3-nice-bots;
        }

# That's all folk
}
