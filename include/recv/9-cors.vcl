
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

## Incoming
sub cors-9 {
	if (req.http.Origin) {
		std.log("CORS check: incoming request with Origin: " + req.http.Origin + " → URL: " + req.url);

	# Whitelist allowed origins using regular expression
        if (req.http.Origin ~ "^(https://www\.katiska\.eu|https://www\.eksis.\.one|https://www\.poochierevival\.info)$") {
		set req.http.X-Saved-Origin = req.http.Origin;
		std.log("CORS accepted: " + req.http.Origin);
	} else {
		std.log("CORS denied: " + req.http.Origin);
		}
	}
}


# The end

