sub be_started {

	### vcl_backend_respone, first part

	## Add name of backend in varnishncsa log
	# You can find slow replying backends (over 3 sec) with that:
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' | awk '$7 > 3 {print}'
	# or
	# varnishncsa -b -F '%t "%r" %s %{Varnish:time_firstbyte}x %{VCL_Log:backend}x' -q "Timestamp:Beresp[3] > 3 or Timestamp:Error[3] > 3"
	std.log("backend: " + beresp.backend.name);
	
	## Let's create a couple helpful tag'ish
	set beresp.http.x-url = bereq.url;
	set beresp.http.x-host = bereq.http.host;
	
	## Will kick in if backend is sick
	if (bereq.url ~ "^/wp-json/" || bereq.url ~ "^/wp-admin/") {
		# no grace for admins
		set beresp.grace = 0s;
	} else {
	        set beresp.grace = 12h;
	}

	    # Jos käytössä on snapshot-backendi ja vastaus on 200, vaihda se 503:ksi
    if (bereq.backend == snapshot_nginx && beresp.status == 200) {
        std.log(">> Snapshot backend responded 200 — rewriting to 302");
        set beresp.status = 302;
        set beresp.reason = "Service Unavailable (snapshot)";
    }

    # Jos saatiin backend-virhe (500/502/503/504)
    if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {

        # Jos tämä oli taustahaku (esim. grace-toimituksen jälkeen), hylätään
        if (bereq.is_bgfetch) {
            std.syslog(180, "Backend failure, abandoning bgfetch for " + bereq.url);
            return(abandon);
        }

        # Estä välimuisti vain, jos ei olla snapshotissa
        if (bereq.backend != snapshot_nginx) {
            std.syslog(180, "Backend failure, marking response uncacheable: " + bereq.url);
            set beresp.uncacheable = true;
        }
    }

    # Snapshot-backendille määritetään erillinen cachelogiikka
    if (bereq.backend == snapshot_nginx) {
        # Varmistetaan, että snapshotit menevät cacheen lyhyeksi aikaa
        set beresp.ttl = 60m;
        set beresp.grace = 15m;
        set beresp.keep = 2m;
        #std.syslog(180, "Snapshot backend, setting short TTL/grace: " + bereq.url);
    }	
	## xkey for smarter PURGE
#	if (beresp.http.X-Cache-Tags) {
#		set beresp.http.xkey = beresp.http.X-Cache-Tags;
#	}

	## ESI is enabled and now in use if needed
	# except... I didn't configured this on MISS
	#if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
	#	unset beresp.http.Surrogate-Control;
	#	set beresp.do_esi = true;
	#}

}
