sub user_agents {

	### Central station for tidying user-agents.
	## I could normalize UA, but nowadays I leave is as it is, and adding two x-headers:
	## x-bot and x-user-agent

	## These should be marked as real users, but some aren't
	call real_users.vcl;


# That's all folk
}
