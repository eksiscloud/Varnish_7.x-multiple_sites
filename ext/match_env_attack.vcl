sub match_env_attack {
    if (req.url ~ "(/\.env)") {
        if (req.http.X-Country-Code ~ "fi" || req.http.X-Accept-Language ~ "fi") {
            return (synth(403, "Forbidden"));
        } else {
            return (synth(666, "Security issue"));
        }
    }
}