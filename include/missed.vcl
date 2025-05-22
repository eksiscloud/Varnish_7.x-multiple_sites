sub missit {

	### Whole vcl_miss

	## Miss counter
	set req.http.x-cache = "miss";

	## ESI
	# I don't know how to handle ESI or do I need it at all
	# ESI is enabled in backend and I don't know what I should put in
	# (object needs ESI processing)
	#if (object needs ESI processing) {
	#	unset req.http.accept-encoding;
	#}

	if (req.method == "PURGE") {
		
		## Hard purge sets all values (TTL, grace, keep) to 0 sec (plus build-in T>
#               set req.http.purged = purge.hard();

#               if (req.http.purged == "0") {
#                       return(synth(404));
#               } else {
#                       return(synth(200, req.http.purged + " items purged."));
#               }
        
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
