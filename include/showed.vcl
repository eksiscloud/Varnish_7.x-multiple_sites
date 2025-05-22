sub showit {

	### The last part of vcl_deliver, manipulating headers etc.

	## Using ETAG (content based) by backend is more accurate than Last-Modified (time based), 
	# but I want to get last-modified because I'm curious, even curiosity kills the cat
	set resp.http.Modified = resp.http.Last-Modified;
	unset resp.http.Last-Modified;
	
	## Just to be sure who is seeing what
	if (req.http.x-bot) {
		set resp.http.debug = req.http.x-bot;
	}
	
	## Expires and Pragma  are unneeded because cache-control overrides it
	unset resp.http.Expires;
	unset resp.http.Pragma;
	
	## Remove some headers, because the client doesn't need them
	unset resp.http.Server;
	unset resp.http.X-Powered-By;
	unset resp.http.Via;
	#unset resp.http.Link;
	unset resp.http.X-Generator;
	unset resp.http.x-url;
	unset resp.http.x-host;
	
	# Why? I don't know
	set resp.http.X-Varnish = req.http.X-Varnish;
	unset resp.http.X-Varnish;
	## Custom headers, not so serious thing 
	set resp.http.Your-Agent = req.http.User-Agent;
	set resp.http.Your-IP = req.http.X-Real-IP;
	#set resp.http.Your-Language = req.http.Accept-Language;

}
