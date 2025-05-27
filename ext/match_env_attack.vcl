sub match_env_attack {
    if (req.url ~ "^/(/\\\.env)") {
        if (req.http.X-County-Code ~ "fi" || req.http.X-Language ~ "fi") {
            return (synth(403, "Forbidden"));
        } else {
            return (synth(666, "Security issue"));
        }
    }
}