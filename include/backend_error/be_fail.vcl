sub be_fail {

    ## There isn't a retry yet, so do it
    if (bereq.retries == 0) {
        std.syslog(180, "ALERT: Apache is not responding on first attempt: " + bereq.http.host + bereq.url);
        std.log(">> Backend error: first retry");
        return (retry);
    }

    ## First retry is done and backend is still down. Change to snapshot-server.
    if (bereq.retries == 1 &&
        (beresp.status == 500 || beresp.status == 503 || beresp.status == 504)) {
        std.log(">> Backend error: switching to snapshot backend");
        set bereq.backend = snapshot;
        return (retry);
    }

    ## Nothing works and now it's time to show error
    std.syslog(180, "ALERT: snapshot and Apache2 down " + bereq.http.host + bereq.url);
    std.log(">> Backend error: all retries failed");
    return (fail);

## Stub stops here
}
