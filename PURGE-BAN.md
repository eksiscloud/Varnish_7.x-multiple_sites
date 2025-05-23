# Soft PURGE

PURGE actually does BAN

## Current Architecture and Operation

**PURGE and BAN Logic (vcl_recv)**

* All PURGE, BAN, and REFRESH requests are handled centrally in the vcl_recv section.
* A request is accepted only if the X-Real-IP is on the whitelist (e.g., localhost or the VPS's IP).
* Three types of PURGE functionality have been implemented:

  * xkey-purge: if the xkey-purge header is included, a ban("obj.http.X-Cache-Tags ~ ...") is executed.
  * File path-based ban: e.g., /wp-content/uploads/audio/ or /images/.
  * Other PURGE requests are directed to normal hash processing (return(hash)), allowing Varnish to invalidate the exact given URL.

**vcl_hit / vcl_miss / vcl_purge**

* Removed or commented out the old PURGE soft/hard logic that repeated purge.soft() or purge.hard() calls.
* No longer a need for separate TTL variable settings or a restart mechanism.

**xkey-purge Support**

* Varnish executes a ban() command based on the HTTP header X-Cache-Tags.
* This allows for selective cache purges, e.g., articles, sidebars, homepage, etc.

**Support for curl and shell scripts**

* Standardized PURGE interface (curl -X PURGE ...).
