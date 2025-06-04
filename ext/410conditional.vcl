sub conditional410 {

	### Conditional error 410, kind of
	## If the backend gives 404, then that request will be chandeg to 410 and cached for 24 hours.
	## But if the situation sometimes changes, as can happend with arxhive sub-pages, 200 is given and
	## business as usual will happen.
	## Don't use that for real 410s. Only for urls that can return.
	## This is not 100% sure trick. The canonical redirection of Wordpress may give pure 200 and
	## redirect to frontpage. if that happens and you know problematic url structure, change it
	## in the vcl_recv, not when backend response has been given.

	
	if (beresp.status == 404 &&  (
		bereq.url ~ "/wp-content/cache/" || # old WP Rocket cachefiles, that Bing can't handle
		bereq.url ~ "/page/" || # empty archive sub categories
		bereq.url ~ "/feed/" # old RSS feeds
		)) {
			set beresp.ttl = 86400s;
			set beresp.status = 410;
			return(deliver);
	}

# The end of this sub
}
