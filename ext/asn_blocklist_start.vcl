sub asn_blocklist_start {

	## Not ASN but is here anyway: stopping some sites using ACL and reverse DNS
        if (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ forbidden) {
                return (synth(403, "Access Denied " + req.http.X-Real-IP));
        }

        ## If you have just another website for real users maybe It is wise move to ban every single one VPS service
        ## you don't need for APIs etc.
        # Heads up: ASN can and quite often will stop more than just one company
        # Just coming from some ASN doesn't be reason to hard banning,
        # but everyone here is knocking too often so I'll keep doors closed

	# ASN can be empty sometimes. i stop those request, because it is suspicious
	if (req.http.X-ASN-ID == "unknown") {
                std.log("Missing ASN-ID for: " + req.http.X-Real-IP);
                return(synth(400, "Missing ASN-ID"));
        }

	# Let`s filtering
	call asn_name;
	call asn_blocklist;

# The sub stops here
}
