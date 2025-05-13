# These are ~/.bash_aliases I use to make my life a little bit easier.
# Some of this might be smarter to use as script, but I don't know how.
# So my solution after updating a VCL, let's say sites/katiska.eu.vcl, is this:
#
# v-ok sites/katiska.vcl
# load-katiska
# label-katiska <name-of-just-loaded-new-vcl-version>

# VCL
alias v-ok='varnishd -C -f '
alias load-root='varnishadm vcl.load root-orig-$(date +%s) /etc/varnish/default.vcl && varnishadm vcl.list'
alias load-katiska='varnishadm vcl.load katiska-orig-$(date +%s) /etc/varnish/sites/katiska.eu.vcl && varnishadm vcl.list'
alias load-eksis='varnishadm vcl.load eksis-orig-$(date +%s) /etc/varnish/sites/eksis.one.vcl && varnishadm vcl.list'
alias load-jagster='varnishadm vcl.load jagsterone-orig-$(date +%s) /etc/varnish/sites/jagster.eksis.vcl && varnishadm vcl.list'
alias load-dev='varnishadm vcl.load devone-orig-$(date +%s) /etc/varnish/sites/dev.eksis.vcl && varnishadm vcl.list'
alias load-selko='varnishadm vcl.load selkokatiska-orig-$(date +%s) /etc/varnish/sites/selko.katiska.vcl && varnishadm vcl.list'
alias load-store='varnishadm vcl.load store-orig-$(date +%s) /etc/varnish/sites/store.katiska.vcl && varnishadm vcl.list'
alias label-katiska='varnishadm vcl.label katiska '
alias label-eksis='varnishadm vcl.label eksisone '
alias label-jagster='varnishadm vcl.label jagster '
alias label-dev='varnishadm vcl.label dev '
alias label-selko='varnishadm vcl.label selkokatiska '
alias label-store='varnishadm vcl.label store '
alias probe='varnishadm backend.list'
alias a-ok='apache2ctl configtest'

#  Echoed ones
alias warm-katiska='wget --spider -o wget.log -e robots=off -r -l 5 -p -S -T3 --header="X-Bypass-Cache: 1" --header="User-Agent:CacheWarmer" -H --domains=katiska.eu --show-progress www.katiska.eu'
alias warm-one='wget --spider -o wget.log -e robots=off -r -l 5 -p -S -T3 --header="X-Bypass-Cache: 1" --header="User-Agent:CacheWarmer" -H --domains=eksis.one --show-progress www.eksis.one'
alias warm-jagster='wget --spider -o wget.log -e robots=off -r -l 5 -p -S -T3 --header="X-Bypass-Cache: 1" --header="User-Agent:CacheWarmer" -H --domains=jagster.fi --show-progress www.jagster.fi'
alias warmup='warm-jagster && warm-one && warm-katiska'
alias ban-katiska='varnishadm "ban req.http.host == www.katiska.eu" && varnishadm ban.list'
alias ban-one='varnishadm "ban req.http.host == www.eksis.one" && varnishadm ban.list'
alias ban-jagster='varnishadm "ban req.http.host == www.jagster.fi" && varnishadm ban.list'
alias purge='curl -X PURGE '
