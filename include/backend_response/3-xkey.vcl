sub xkey-3 {

	### vcl_backend_respone, third part

        ## Set xkey
        if (beresp.http.X-Cache-Tags) {
            set beresp.http.xkey = beresp.http.X-Cache-Tags;
        }

        ## Add domain-xkey if not already there
        if (bereq.http.host) {
            if (bereq.http.host == "www.katiska.eu" && !std.strstr(beresp.http.xkey, "domain-katiska")) {
                set beresp.http.xkey += ",domain-katiska";
            } else if (bereq.http.host == "www.poochierevival.info" && !std.strstr(beresp.http.xkey, "domain-poochie")) {
                set beresp.http.xkey += ",domain-poochie";
            } else if (bereq.http.host == "www.eksis.one" && !std.strstr(beresp.http.xkey, "domain-eksis")) {
                set beresp.http.xkey += ",domain-eksis";
            } else if (bereq.http.host == "jagster.eksis.one" && !std.strstr(beresp.http.xkey, "domain-jagster")) {
                set beresp.http.xkey += ",domain-jagster";
            } else if (bereq.http.host == "dev.eksis.one" && !std.strstr(beresp.http.xkey, "domain-dev")) {
                set beresp.http.xkey += ",domain-dev";
            }
        }

        ## Add xkey for tags if not already there
        if (bereq.url ~ "^/") {
            # This trick must be done beacuse strings can't be joined with regex-operator
            set beresp.http.X-URL-CHECK = "url-" + bereq.url;
    
            if (!std.strstr(beresp.http.xkey, beresp.http.X-URL-CHECK)) {
                set beresp.http.xkey += "," + beresp.http.X-URL-CHECK;
            }

            unset beresp.http.X-URL-CHECK;
        }

## The end is here
}
