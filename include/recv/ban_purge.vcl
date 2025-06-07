sub ban_purge {

	### Using just BAN here

    if (req.method == "BAN") {
        # Tarkistetaan, että vain luotetut IP-osoitteet voivat tehdä BANeja
        if (req.http.X-Bypass != "true") {
            return(synth(403, "Forbidden"));
        }

        # Varnish 7+: BAN vaatii eksplisiittiset ehdot
        ban("req.http.host == " + req.http.host + " && req.url ~ " + req.url);

        return(synth(200, "Banned"));
    }
}

# the end of this stub
}
