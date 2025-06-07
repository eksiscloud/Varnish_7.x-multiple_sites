sub asn_id {

	## If you have just another website for real users maybe It is wise move to ban every single one VPS service
	## you don't need for APIs etc.
	# Heads up: ASN can and quite often will stop more than just one company
	# Just coming from some ASN doesn't be reason to hard banning,
	# but everyone here is knocking too often so I'll keep doors closed

	# M247 is really bad apple. I want to know how many times it is involved
	if (req.http.X-ASN ~ "(?i)m247|ipxo|drh" || req.http.X-ASN ~ "AS9009") {
		set req.http.X-Match = "asn-m247-variant";
		return(synth(466, "Blocked: ASN M247"));
	}

	## These are constantly problems, so I stop them right away.
	if (
       req.http.x-asn-id == "397630"  # Integral Ad Science / Blazing SEO LLC, US
    || req.http.x-asn-id == "213035"  # Serverion BV, NL
    || req.http.x-asn-id == "4134"    # ChinaNet Backbone / China Telecom, CN
    || req.http.x-asn-id == "36352"   # ColoCrossing, US
    || req.http.x-asn-id == "216211"  # Cyberverse LLC, US
    || req.http.x-asn-id == "47987"   # DeltaHost, UA
    || req.http.x-asn-id == "26347"   # DreamHost, US
    || req.http.x-asn-id == "42159"   # Emerald Onion / Tor Exit, UA
    || req.http.x-asn-id == "20860"   # IOMART Hosting Ltd., GB
    || req.http.x-asn-id == "8560"    # 1&1 IONOS, DE
    || req.http.x-asn-id == "60781"   # LeaseWeb NL, NL
   # || req.http.x-asn-id == "9009"    # M247 Ltd, GB
    || req.http.x-asn-id == "33387"   # Nocix LLC, US
    || req.http.x-asn-id == "16276"   # OVH SAS, FR
    || req.http.x-asn-id == "208046"  # PEENQ / Squitter / Wellnet, NL
    || req.http.x-asn-id == "53667"   # FranTech Solutions (PonyNet), US
    || req.http.x-asn-id == "134763"  # Ngok Fung trading / Powerline-AS, HK
    || req.http.x-asn-id == "49505"   # Selectel, RU
    || req.http.x-asn-id == "29066"   # velia.net, DE
    || req.http.x-asn-id == "4809"    # China Telecom NextGen (lisätty varmistukseksi), CN
) {
    std.log("banned ASN-ID: " + req.http.x-asn-id + " " + req.http.X-Real-IP + " " + req.http.X-Country-Code + " " + req.http.User-Agent);
    return(synth(466, "Severe security issues: ASN-ID " + req.http.x-asn-id));
}

# The end of the sub
}
