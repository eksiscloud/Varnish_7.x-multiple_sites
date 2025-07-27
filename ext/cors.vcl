
	### vcl_cors.vcl – Varnish VCL template for conditional CORS handling
	#	
	# This demonstrates safe and modular CORS configuration using the `X-Saved-Origin` pattern.
	# It does not enable CORS by default unless the origin is explicitly whitelisted.
	#
	# Why this structure?
	# - Cross-origin requests are not needed for normal WordPress operation (HTML/CSS/JS from same origin).
	# - Enabling wildcards (e.g. `*`) or reflecting Origin blindly is insecure.
	# - This setup is easy to expand and debug safely.
	#
	# Reading logs:
	# varnishlog -g request -q 'ReqHeader:Origin'
	# journalctl -u varnish


## Outgoing
sub cors_deliver {

        if (req.http.X-Saved-Origin) {
                set resp.http.Access-Control-Allow-Origin = req.http.X-Saved-Origin;
                set resp.http.Access-Control-Allow-Methods = "GET, POST, OPTIONS";
                set resp.http.Access-Control-Allow-Headers = "Content-Type, Authorization";
                set resp.http.Access-Control-Allow-Credentials = "true";
                set resp.http.X-CORS-Debug = "Enabled for " + req.http.X-Saved-Origin;
        } else {
                unset resp.http.Access-Control-Allow-Origin;
                unset resp.http.Access-Control-Allow-Methods;
                unset resp.http.Access-Control-Allow-Headers;
                unset resp.http.Access-Control-Allow-Credentials;
                unset resp.http.X-CORS-Debug;
        }
}
