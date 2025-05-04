sub new_direction {

	if (req.http.host ~ "www.katiska.eu") {
		## URL manipulations, mostly searches(typos, strange spelling etc.)
		# For some reason if (req.url ~ <url>) {set req.url = <new-url>} doesn't work, must use regsub
		# Scandinavian and other alphabets than a-z must be coded
		# å = Å =
		# ä = \%C3\%A4 Ä =
		# ö = \%C3\%B6 Ö =
		
		# Searches
		if (req.url ~ "\?s=koira$") { set req.url = regsub(req.url, "\?s=koira$", "/tieto/katiskan-kaytto-sisalto/asian-loytaminen/"); return(restart); } # why I need restart here?
		elseif (req.url ~ "/search/50%2F50") { set req.url = regsub(req.url, "/search/50%2F50", "/search/50-F50"); } 
		elseif (req.url ~ "\?s=a2-vitamiini") { set req.url = regsub(req.url, "\?s=a2-vitamiini", "\?s=a-vitamiini"); }
		elseif (req.url ~ "\?s=d3$") { set req.url = regsub(req.url, "\?s=d3$", "\?s=d-vitamiini"); }
		elseif (req.url ~ "\?s=be$") { set req.url = regsub(req.url, "\?s=be$", "\?s=be-vitamiini"); }
		elseif (req.url ~ "\?s=glucosamiini") { set req.url = regsub(req.url, "\?s=glucosamiini", "\?s=glukosamiini"); }
		elseif (req.url ~ "\?s=(.*)juonti") { set req.url = regsub(req.url, "\?s=(.*)juonti", "\?s=juominen"); }
		elseif (req.url ~ "\?s=(kasvis\%C3\%B6ljy|kasvis\%C3\%B6ljyvertailu)") { set req.url = regsub(req.url, "\?s=(kasvis\%C3\%B6ljy|kasvis\%C3\%B6ljyvertailu)", "\?s=kasvi\%C3\%B6ljy"); }
		elseif (req.url ~ "\?s=liha(py\%C3\%B6rykk\%C3\%A4|py\%C3\%B6ryk\%C3\%A4t)") { set req.url = regsub(req.url, "\?s=liha(py\%C3\%B6rykk\%C3\%A4|py\%C3\%B6ryk\%C3\%A4t)", "\?s=lihapulla"); }
		elseif (req.url ~ "\?s=luuharventuma") { set req.url = regsub(req.url, "\?s=luuharventuma", "\?s=osteoporoosi"); }
		elseif (req.url ~ "\?s=maksa(pulla|py\%C3\%B6rykk\%C3\%A4|py\%C3\%B6ryk\%C3\%A4t)") { set req.url = regsub(req.url, "\?s=maksa(pulla|py\%C3\%B6rykk\%C3\%A4|py\%C3\%B6ryk\%C3\%A4t)", "\?s=maksa\+vitamiinipulla"); }
		elseif (req.url ~ "\?s=m\%C3\%A4k\%C3\%A4r\%C3\%A4inen") { set req.url = regsub(req.url, "\?s=m\%C3\%A4k\%C3\%A4r\%C3\%A4inen", "\?s=m\%C3\%A4k\%C3\%A4r\%C3\%A4"); }
		elseif (req.url ~ "\?s=vitamiinin(tarve|tarpeet)") { set req.url = regsub(req.url, "\?s=vitamiinin(tarve|tarpeet)", "\?s=vitamiinin\+tarve"); }
		elseif (req.url ~ "\?s=proteiininl\%C3\%A4hde") { set req.url = regsub(req.url, "\?s=proteiininl\%C3\%A4hde", "\?s=proteiinien+l\%C3\%A4hde"); }
		elseif (req.url ~ "\?s=(punkki|punkin)esto") { set req.url = regsub(req.url, "\?s=(punkki|punkin)esto", "\?s=punkkih\%C3\%A4\%C3\%A4t\%C3\%B6"); }
		elseif (req.url ~ "\?s=rabdomyoloosi") { set req.url = regsub(req.url, "\?s=rabdomyoloosi", "\?s=asidoosi"); }
		elseif (req.url ~ "\?s=raakaliha") { set req.url = regsub(req.url, "\?s=raakaliha", "\?s=raaka\+liha"); }
		elseif (req.url ~ "\?s=rutiinitarkastus") { set req.url = regsub(req.url, "\?s=rutiinitarkastus", "\?s=lihaksiston\+rutiinitarkastus"); }
		elseif (req.url ~ "\?s=ruuansulatuksen\+nopeus") { set req.url = regsub(req.url, "\?s=ruuansulatuksen\+nopeus", "\?s=ruuansulatuksen\+kesto"); }
		elseif (req.url ~ "\?s=syyl\%C3\%A4$") { set req.url = regsub(req.url, "\?s=syyl\%C3\%A4$", "\?s=syyl\%C3\%A4t"); }
		elseif (req.url ~ "\?s=t\%C3\%A4yslihapulla") { set req.url = regsub(req.url, "\?s=t\%C3\%A4yslihapullat", "\?s=lihapulla"); }
		elseif (req.url ~ "\?s=(nappulat|nappularuokinta)") { set req.url = regsub(req.url, "\?s=(nappulat|nappularuokinta)", "\?s=kuivamuona"); }
		elseif (req.url ~ "\?s=nivelterveys") { set req.url = regsub(req.url, "\?s=nivelterveys", "\?s=nivelet"); }
		elseif (req.url ~ "\?s=washout") { set req.url = regsub(req.url, "\?s=washout", "\?s=wash-out"); }
		elseif (req.url ~ "\?s=virtsa(tiekide|kide|tiekiteet|kiteet)") { set req.url = regsub(req.url, "\?s=virtsa(tiekide|kide|tiekiteet|kiteet)", "\?s=virtsakivi\+virtsatiekivi"); }
		elseif (req.url ~ "\?s=vischy") { set req.url = regsub(req.url, "\?s=vischy", "\?s=vichy"); }
		elseif (req.url ~ "\?s=vitamiinilista") { set req.url = regsub(req.url, "\?s=vitamiinilista", "\?s=vitamiinit"); }

	}
	
}
