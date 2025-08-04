sub security {

	### These should come from apps and/or server, but like WordPress doesn't set anything
	### For me this is easier solution because now I can handle everything in one place
	### Everything here works only if not piped.

	# HTTP Strict Transport Security (HSTS)
	# This header instructs browsers to always use HTTPS for this domain,
	# and to remember this preference for the specified duration.
	#
	# Since Varnish does not handle HTTPS directly, it cannot natively
	# determine whether the client originally connected via HTTPS.
	# In a typical architecture (e.g., Nginx → Varnish → Apache),
	# the TLS terminator (Nginx) sets the header X-Forwarded-Proto to
	# indicate the original request scheme.
	#
	# We only add the HSTS header if the original request came in over HTTPS,
	# to avoid misinforming browsers when running on development environments
	# or during HTTP requests that should not trigger HSTS behavior.
	
	if (!resp.http.Strict-Transport-Security && req.http.X-Forwarded-Proto == "https") {
		set resp.http.Strict-Transport-Security = "max-age=31536000; includeSubDomains;";
	}

	## MIME sniffing
	# Applies only if a backend doesn't set sniffing as it normally doesn't; if it comes from frontend, like proxy as Nginx, Varnish doesn't see it
	if (!resp.http.X-Content-Type-Options) {
		set resp.http.X-Content-Type-Options = "nosniff";
	}
	
	## Referrer-Policy
	if (!resp.http.Referrer-Policy) {
		set resp.http.Referrer-Policy = "strict-origin-when-cross-origin";
	}
	
	# I have some embed issues and I need full referring url
	#if (req.http.host ~ "katiska.eu") {
	#	set resp.http.Referrer-Policy = "unsafe-url";
	#}
	# but this might be better:
	# safer fallback if full referrer not needed anymore
	if (req.http.host ~ "katiska.info") {
		set resp.http.Referrer-Policy = "strict-origin-when-cross-origin";
	}
	
	## Remove X-Frame-Optios if CSP is in use
	if (resp.http.Content-Security-Policy) {
		unset resp.http.X-Frame-Options;
	}

	# Add X-Frame.Options if both are missing
	elseif (!resp.http.Content-Security-Policy && !resp.http.X-Frame-Options) {
		set resp.http.X-Frame-Options = "sameorigin";
	}
	
	## Cleaning unnecessary headers
	if (resp.http.obj ~ "\.(appcache|atom|bbaw|bmp|crx|css|cur|eot|f4[abpv]|flv|geojson|gif|htc|ic[os]|jpe?g|m?js|json(ld)?|m4[av]|manifest|map|markdown|md|mp4|oex|og[agv]|opus|otf|pdf|png|rdf|rss|safariextz|svgz?|swf|topojson|tt[cf]|txt|vcard|vcf|vtt|webapp|web[mp]|webmanifest|woff2?|xloc|xpi)$") {
		unset resp.http.X-UA-Compatible;
		unset resp.http.X-XSS-Protection;
	}
	
	if (resp.http.obj ~ "\.(appcache|atom|bbaw|bmp|crx|css|cur|eot|f4[abpv]|flv|geojson|gif|htc|ic[os]|jpe?g|json(ld)?|m4[av]|manifest|map|markdown|md|mp4|oex|og[agv]|opus|otf|png|rdf|rss|safariextz|swf|topojson|tt[cf]|txt|vcard|vcf|vtt|webapp|web[mp]|webmanifest|woff2?|xloc|xpi)$") {
		unset resp.http.Content-Security-Policy;
	}
	
	## Cookies
	# Cookies can be done, manipulated and changed using Varnish. But I can't.
	# Instead manipulation here these should be in wp-config.php of WordPress:
	# @ini_set('session.cookie_httponly', true); 
	# @ini_set('session.cookie_secure', true); 
	# @ini_set('session.use_only_cookies', true);
	
# the end of the sub
}
