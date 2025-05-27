sub close_doors {

	## The easiest way update Geo banning.
	# Just using ($server_protocol = HTTP/1.0) { return 444; } in Nginx blocks plenty of these
	if (req.http.X-Country-Code ~
                "(bd|bg|br|by|ch|cn|cr|cz|ec|fr|ro|rs|ru|sy|hk|id|in|iq|ir|kr|ly|my|ph|pl|sc|sg|tr|tw|ua|vn)"
        ) {
		set req.http.x-ban-country = req.http.X-Country-Code;
	}

# That's it
}
