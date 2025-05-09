sub new_one {

	if (req.http.host == "www.katiska.info" && req.http.url ~ "^/wp-login") {
		set req.backend_hint = default;
		return(synth(666));
	} 
	if (req.http.host ~ "www.katiska.info") {
		set req.backend_hint = default;
		return(synth(701, "https://www.katiska.eu" + req.url));
	}

	if (req.http.host ~ "store.katiska.info") {
		set req.backend_hint = default;
		return(synth(701, "https://store.katiska.eu" + req.url));
	}

	if (req.http.host ~ "selko.katiska.info") {
		set req.backend_hint = default;
                return(synth(701, "https://selko.katiska.eu" + req.url));
        }
	
	if (req.http.host ~ "meta.katiska.info") {
                set req.backend_hint = default;
                return(synth(701, "https://foorumi.katiska.eu" + req.url));
        }

	if (req.http.host ~ "jagster.fi") {
                set req.backend_hint = default;
                return(synth(701, "https://jagster.eksis.one" + req.url));
        }
}
