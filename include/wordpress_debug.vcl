

sub wordpress_debug {
    std.log(">> DEBUG: vcl_recv start");

    if (
        req.method == "POST" ||
        req.method == "PUT" ||
        req.method == "PATCH" ||
        req.method == "DELETE"
    ) {
        std.log(">> DEBUG: return(pass) due to method: " + req.method);
        return (pass);
    }

    if (req.http.Authorization) {
        std.log(">> DEBUG: return(pass) due to Authorization header");
        return (pass);
    }

    if (req.http.Cookie ~ "wordpress_") {
        std.log(">> DEBUG: return(pass) due to wordpress_ cookie");
        return (pass);
    }

    if (req.http.Cookie ~ "comment_") {
        std.log(">> DEBUG: return(pass) due to comment_ cookie");
        return (pass);
    }

    if (req.http.X-Requested-With == "XMLHttpRequest") {
        std.log(">> DEBUG: return(pass) due to XMLHttpRequest");
        return (pass);
    }

    if (req.url ~ "wp-(login|admin)") {
        std.log(">> DEBUG: return(pass) due to wp-login/wp-admin URL");
        return (pass);
    }

    if (req.url ~ "preview=true") {
        std.log(">> DEBUG: return(pass) due to preview=true in URL");
        return (pass);
    }

    std.log(">> DEBUG: passed all pass conditions");

    return (hash);
}
