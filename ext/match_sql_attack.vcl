sub match_sql_attack {
    if (req.url ~ "^/(backup\.sql|\^/database\.sql|/db_dump\.sql|/katiskainfo\.sql|mysql\.sql|/site\.sql|source\.sql|web\.sql)") {
        if (req.http.X-County-Code ~ "fi" || req.http.X-Language ~ "fi") {
            return (synth(403, "Forbidden"));
        } else {
            return (synth(666, "Security issue"));
        }
    }
}