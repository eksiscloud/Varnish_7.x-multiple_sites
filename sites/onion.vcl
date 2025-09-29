# Jakke Lehtonen
##
## First version for testing, if this is possible at all.
## That's why this version is for one host only.
## 
## * * * * *
## Builded from several sources
## Heads up! There is errors for sure
## I'm just another copypaster
##
## Varnish 7.7.1 default.vcl/onion.vcl for onion mirror for tor use.
## 
## onion.vcl, same as default.vcl, is splitted in few sub vcls. Those use includes.  
## That make updating much more easier, because most of my hosts are WordPresses.
##
## This works as a standalone VCL for one WordPress host too
##  
## Lets's start caching (...and a little bit more)

########

# Marker to tell the VCL compiler that this VCL has been adapted to the 4.1 format.
vcl 4.1;


backend wp {
  .host = "127.0.0.1";
  .port = "8081";
  .first_byte_timeout = 60s;
  .between_bytes_timeout = 30s;
}

sub vcl_recv {
  set req.backend_hint = wp;

  # Cache only GET/HEAD
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

  # ONION-branch
  if (req.http.host ~ "(?i)rqqkvluwdb2hiqgu2mrnlby5o3s4o35kwelgmuh6y7lzj2bkpej3jxid\\.onion$") {
    # Proxy right proto  + do not chain IP`ish of Tor
    remove req.http.X-Forwarded-For;
    set req.http.X-Forwarded-For = "127.0.0.1";
    set req.http.X-Forwarded-Proto = "http";

    # Send cookie/POST/admin to clearnet
    if (req.http.Cookie
        || req.url ~ "(?i)(wp-login\\.php|wp-admin|/admin|/account|/signin|/checkout|/cart)"
        || req.method == "POST") {
      set req.http.X-Redirect-Target = "https://www.eksis.one" + req.url;
      return (synth(302, "Redirect to clearnet"));
    }
  } else {
    # CLEARNET: be sure about proto, because Varnish is behind TLS-terminating
    if (!req.http.X-Forwarded-Proto) { set req.http.X-Forwarded-Proto = "https"; }
  }

  return (hash);
}

#### vcl_synth ####
#
sub vcl_synth {
  if (resp.status == 302 && req.http.X-Redirect-Target) {
    set resp.http.Location = req.http.X-Redirect-Target;
    set resp.http.Cache-Control = "no-store";
  }
  return (deliver);
}

#### vcl_backend_response ####
#
sub vcl_backend_response {
  # There is no HSTS or Secure-flags in onion
  if (bereq.http.host ~ "(?i)rqqkvluwdb2hiqgu2mrnlby5o3s4o35kwelgmuh6y7lzj2bkpej3jxid\\.onion$") {
    unset beresp.http.Strict-Transport-Security;

    # if a backend tries redirect to clearnet, keep onion
    if (beresp.status == 301 || beresp.status == 302 || beresp.status == 303
        || beresp.status == 307 || beresp.status == 308) {
      if (beresp.http.Location) {
        set beresp.http.Location = regsub(beresp.http.Location,
          "(?i)^https?://(www\\.)?eksis\\.one", "http://rqqkvluwdb2hiqgu2mrnlby5o3s4o35kwelgmuh6y7lzj2bkpej3jxid.onion");
      }
    }

    # Do not allow cookies from a backend
    if (beresp.http.Set-Cookie) { 
      unset beresp.http.Set-Cookie;
    }

    # Optional: block 3rd party scripts
    # set beresp.http.Content-Security-Policy = "default-src 'self' data:; img-src 'self' data: https:; script-src 'self'; style-src 'self' 'unsafe-inline'; frame-ancestors 'self'; object-src 'none'";

    # Fix TTLs later, now short one
    if (beresp.ttl <= 0s) { set beresp.ttl = 30m; }

  # These urls aren't allowed here. Must clean this at some point.
  if (beresp.http.Set-Cookie && bereq.url !~ "(?i)(wp-login\\.php|wp-admin|/cart|/checkout)") {
    unset beresp.http.Set-Cookie;
  }

  return (deliver);
}


#### vcl_deliver ####
#
sub vcl_deliver {
  if (req.http.host ~ "(?i)rqqkvluwdb2hiqgu2mrnlby5o3s4o35kwelgmuh6y7lzj2bkpej3jxid\\.onion$") {
    set resp.http.X-Onion = "1";
  } else {
    remove resp.http.X-Onion;
  }
}
