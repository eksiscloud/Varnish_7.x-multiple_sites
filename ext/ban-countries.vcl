sub close_doors {

	## The easiest way update Geo banning.

	if (req.http.X-Country-Code ~
                "(bd|bg|br|by|cn|cr|cz|ec|fr|ro|rs|ru|sy|hk|id|in|iq|ir|kr|ly|my|ph|pl|sc|sg|tr|tw|ua|vn)"
        ) {
		set req.http.x-ban-country = req.http.X-Country-Code;
	}

# That's it
}
