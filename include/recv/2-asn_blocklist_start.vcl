sub asn_blocklist_start-2 {

        ## If you have just another website for real users maybe It is wise move to ban every single one VPS service
        ## you don't need for APIs etc.
        # Heads up: ASN can and quite often will stop more than just one company
        # Just coming from some ASN doesn't be reason to hard banning,
        # but everyone here is knocking too often so I'll keep doors closed

	## ASN can be empty sometimes. Nginx changes it to unknown for easier reading. 
	# I stop those request, because it is suspicious
	if (req.http.X-ASN-ID == "unknown") {
                std.log("Missing ASN-ID: " + req.http.X-Real-IP + " " + req.http.Country-Code);
                return(synth(400, "Missing ASN-ID"));
        }

	# Let`s filtering
	call asn_id-2-1;
	call asn_blocklist;

# The sub stops here
}
