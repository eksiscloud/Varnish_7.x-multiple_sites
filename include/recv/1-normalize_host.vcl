sub normalize_host-1 {

	## Just normalizing host names
	# I like to keep triple-w
        
	set req.http.host = regsub(req.http.host,
        "^katiska\.eu$", "www.katiska.eu");
         
	set req.http.host = regsub(req.http.host,
        "^eksis\.one$", "www.eksis.one");

	set req.http.host = regsub(req.http.host,
        "^poochierevival\.info$", "www.poochierevival.info");

	## Give 127.0.0.1 to X-Real-IP if curl is used from localhost
        # (std.ip(req.http.X-Real-IP, "0.0.0.0") goes to fallbck when curl is used from localhost and fails
        # Because Nginx acts as a reverse proxy, client.ip is always its IP.
        # Now we get some IP when worked from home shell
        # This should or could be among other normalizin, but I want this before bot filtering
	if (!req.http.X-Real-IP || req.http.X-Real-IP == "") {
                set req.http.X-Real-IP = client.ip;
        }

std.log(">> DEBUG: URL = " + req.url);

if (req.http.cookie) {
    std.log(">> DEBUG: Cookie when entering = " + req.http.cookie);
} else {
    std.log(">> DEBUG: No Cookie header at all");
}

if (req.http.X-Bypass) {
    std.log(">> DEBUG: X-Bypass = " + req.http.X-Bypass);
}

if (req.http.X-Bypass-Cache) {
    std.log(">> DEBUG: X-Bypass-Cache = " + req.http.X-Bypass-Cache);
}

if (req.http.User-Agent) {
    std.log(">> DEBUG: UA = " + req.http.User-Agent);
}

if (req.http.Sec-Fetch-Site) {
    std.log(">> DEBUG: Sec-Fetch-Site = " + req.http.Sec-Fetch-Site);
}

# it ends here
}
