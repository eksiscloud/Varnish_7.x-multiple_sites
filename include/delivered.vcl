sub deliverit {

	### vcl_deliver, first part

	## Damn, backend is down (or the request is not allowed; almost same thing)
	if (resp.status == 503) {
		return(restart);
	}
	
	## Knockers with 404 will get synthetic error 666 that leads to real error 666
	if (resp.status == 666) {
		return(synth(666, "Requests not allowed for " + req.url));
	}

	## Debug for 403
	#if (resp.status == 403) {
	#	call debug_headers;
	#}

	## And now I remove my helpful tag'ish
	# Now something like this works:
	# varnishlog -c -g request -i Req* -i Resp* -I Timestamp:Resp -x ReqAcct -x RespUnset -X "RespHeader:(x|X)-(url|host)" 
	unset resp.http.x-url;
	unset resp.http.x-host;

	## Vary to browser
	set resp.http.Vary = "Accept-Encoding";

	## Origin should send to browser
	set resp.http.Vary = resp.http.Vary + ",Origin";

	## Set xkey visible
#	if (resp.http.X-Cache-Tags) {
#	        set resp.http.X-Cache-Tags = resp.http.X-Cache-Tags;
#	}
}
