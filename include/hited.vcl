sub hitit {

	### Whole vcl_hit

	## Hit counter, grace
	set req.http.x-cache = "hit";
	if (obj.ttl <= 0s && obj.grace > 0s) {
		std.log(">> Cache HIT but TTL expired, serving from grace");
		set req.http.x-cache = "hit graced";
	}

    return (deliver);

}
