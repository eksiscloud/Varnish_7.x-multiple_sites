# BAN/PURGE
Just a note how to BAN some objects from my sites.
* BAN changes TTL to zero and forces requests to get fresh fish. There is `grace`, `hit-to-pass` or something in use, though.
* PURGE destroys objects from the cache right away. There can be `soft PURGE` and `hard PURGE` too, and soft one is same as BAN, I suppose. Which one is in use depends of the configuration from VCL.

BAN/PURGE can be made using two different methods:
* from app or directly from a console using HTTPie, wget, curl etc.
* using `varnishadm`; I recon BAN can be done this way, but PURGE must do using curl or similar ones

I'm using `varnishadm` because it feels more simplier than `curl -X BAN "something"`. Plus my setup has some error and I can't PURGE using curl or HTTPie.

## Examples

* the frontpage, change req.url for everything else
```
varnishadm ban req.http.host == "www.katiska.eu" && req.url ~ ^/"
```

* do this to see what is banned and everything has gone thru and is completed
```
varnishadm ban.list
```

### Paths for my use

**Podcasts:**
```
/feed/podcast/katiska
/feed/podcast/kaffepaussi
```

**WordPress:**
```
/wp-content/themes/
/wp-content/plugins/
```

