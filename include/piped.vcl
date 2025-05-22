sub pipeit {

	## Pipe counter
	set req.http.x-cache = "pipe uncacheable";

	## Implementing websocket support
	if (req.http.upgrade) {
		set bereq.http.upgrade = req.http.upgrade;
		set bereq.http.connection = req.http.connection;
	}

}
