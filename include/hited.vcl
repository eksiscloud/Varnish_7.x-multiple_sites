sub hitit {

	### Whole vcl_hit

	## Hit counter, grace
	set req.http.x-cache = "hit";
	if (obj.ttl <= 0s && obj.grace > 0s) {
		set req.http.x-cache = "hit graced";
	}

	if (req.method == "PURGE") {
		
		## Hard purge sets all values (TTL, grace, keep) to 0 sec (plus build-in TTL I reckon)
#		set req.http.purged = purge.hard();

#		if (req.http.purged == "0") {
#			return(synth(404));
#		} else {
#			return(synth(200, req.http.purged + " items purged."));
#		}
	
		## Soft purge: zero values do same as hard purge
		set req.http.purged = purge.soft(
			std.duration(req.http.ttl,0s),
			std.duration(req.http.grace,120s),
			std.duration(req.http.keep,0s)
		);
	
		if (req.http.purged == "0") {
			return (synth(404));
		} else {
			return (synth(200, req.http.purged + " items purged."));
		}
	
	}

}
