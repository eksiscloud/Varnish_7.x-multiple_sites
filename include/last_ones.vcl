sub these_too {

	## Let's clean User-Agent, just to be on safe side
        # It will come back at vcl_hash, but without separate caching
        # I want send User-Agent to backend because that is the only way to show who is actually getting error 404; 
	# I don't serve bots  and 404 from real users must fix right away
        set req.http.x-agent = req.http.User-Agent;
        if (req.http.x-bot !~ "(nice|tech|bad|visitor)") { set req.http.x-bot = "visitor"; }
        unset req.http.User-Agent;

	## Because vmod Accept isn't in use, we have to remove Accept-Language, because there is no need to cache with it.
	# Let's tranfer to response anyway
	set req.http.x-language = req.http.Accept-Language;
	unset req.http.Accept-Language;

	## I don't need separated caches used by country code, but I use it in responses
	set req.http.x-country = req.http.X-Country-Code;
	unset req.http.X-Country-Code;

# Ends here
}

