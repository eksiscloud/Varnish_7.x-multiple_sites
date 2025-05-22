sub passit {

	## Everything from vcl_pass
        ## Pass counter
        set req.http.x-cache = "pass";

}
