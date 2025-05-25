# Varnish 7.x with multiple sites

My dev-copy of stack Nginx+Varnish+Apache2 with several virtual hosts, bad-bot, unauth 403-urls, GeoIP etc.

This setup uses separate VCLs per site. One default.vcl rules them all and with help of Varnish labelling everything else is divided to separate "site VCLs". Yes, it means you have to edit every single VCL when making a general change. Sub-VCLs are an alternative, but because of every return(...) bypasses in-build VCL, I had always some troubles.

Always be really carefully when you do copy&paste from anywhere.

## Known major issues at the moment

n/a

## The stack

The stack is:

* Nginx listening 80 and 443, redirecting from 80 to 443 is done by Varnish. Nging is terminating SSL and taking care of HTTP/2, plus doing some filtering
* Varnish is listening port 8080 and doing its magic
* Apache2 is the backend listening port 8282

## The setup of Varnish

I've tried comment everything but all I've done are quite basic things and self explaining. It is lightly optimized, and TTLs aren't planned, but chosen by feelings.

The base idea behind TTLs are making compromisses between demand and use of RAM. In most of cases a new article gets attemtion max two days. At same time I'm using shorter TTLs with users and longer for Varnish. The idea behind that is to save space of theirs devices, because 90% of users have mobiles. They quite rarely visit again same resource after one week. Browsers are almot impossible to control, Safari is very famous of really aggressive caching, so I try to be sure that users get fresh content. Varnish on other hand can store objects more longer, because it can serve thwm really fast.

## Limitations

Setup works when terminating of SSL (and some other stuffs) are made on Nginx/Apache2. 
It doesn't work out-of-the-box if font of Varnish is a dumb SSL/TLS-proxy, as Hitch.

There is no point what so ever to use TSL-proxy unless you have thousands SSL-certificates to terminate or
you have some other needs, like load balancing. Using i.e. Hitch forcing you to do all nice things what
a webserver can really well, on Varnish. At same time you will loose easy-reading logs, but sure: you will 
learn how to use varnishlog or varnishnsca to explore basic incoming requests.

## The base

I'm using one VPS, hosting few WordPresses and one WooCommerce.
* Nginx/Varnish (as a hub taking care of virtual hosts and caching; needs more RAM)
* Apache2 as backend for "ordinary" sites (needs more disk, not so much RAM, unless you have dynamic sites like e-commerces)
* do NOT try to put JS-heavy web-apps, as Discourse-forum, behind Varnish - unless there is need to do some exotic things, as load balancing.

## start.cli

Because every site-vcl must be loaded and labeled by varnishadm, it should be done using CLI. The file start.cli will do the job, but it has to be told to Vsrnish

`systemctl edit --full varnish`

And use something like this:

```
ExecStart=/usr/sbin/varnishd \
          -I /etc/varnish/start.cli \
          -P /var/run/varnish.pid \
          -j unix,user=vcache \
          -F \
          -a :8080 \
          -T localhost:6082 \
          -f "" \
          -S /etc/varnish/secret \ 
          -p vsl_mask=+Hash \
          -s malloc,10G
```
Most important parts are `-I /etc/varnish/start.cli` and `-f ""`

I got error `too many \...` so putting all those in one line did the job.

Don't forget `systemctl daemon-reload`

## GeoIP

I'm using GeoIP on Nginx to identify countries and Varnish uses its own vmod to do banning. Both needs extra work when installing/setup, but it is not that hard
job - Google will help you. GeoIP part of Nginx is just a relic from time when I used iptables for banning and filtering, but niw it just gives country in its logs.

## War against bots

Nginx do the work and Varnish is just a backup. There is an example how to do filtering in Varnish, but it is more expensive way than than letting Nginx do the heavy lifting.

## Virtual hosts

Nowadays all my sites behind Varnish are WordPresses, so all site-vcls are identical. There is one WooCommerce, and it does some WC-stuff, but after all it is WordPress too.

### Certbot crashes Ngnix
`certbot renew` can't shutdown and restart Nginx right. Certbot shall shutdown Nginx first and 
after that it tries read nginx.pid and it is not there anymore. That situation is quite common reason for crashed
Nginx because ports are in use by ghost-Nginx. Then you have to do `killall nginx` and after that
`systemctl restart nginx`. When you have backend on dedicated VPS, not as 127.0.0.1, you can't use
--standalone or --webroot either - you are stuck on --nginx even that is the issue.

To fix that you need to
* remove all post/pre settings if such exists (/etc/letsencrypt/cli.ini and renewal/*.host)
* upgrade certbot to version 1.x
* never use crontab to renew certificates; there is system-timer for that
* do pipe; for certbot at very early stage on default.vcl

HEADS UP: I don't think anything of that is really issue anymore. it has fixed now, I reckon. When installed using snap such issues vanished.

## Known limitations

* `varnishd -C -f /etc/varnish/default.vcl` doesn't work.

Do: `varnishd -C -f /etc/varnish/sites/site.vcl`

* `systemctl reload varnish` doesn't work.

Do loading new vcl and connecting to label

`varnishadm vcl.load katiska-orig-$(date +%s) /etc/varnish/sites/katiska.eu.vcl && varnishadm vcl.list`

`vcl.list` gives list of all loaded VCLs and labels. Check what is the name of time stamped one, and then

`varnishadm vcl.label katiska katiska-orig-1746614848`

Now is the new VCL loaded and linked to right label. Same thing than `systemctl reload varnish` but now it must be done per site. That system gives you fast way to roll back, if/when needed. Except if you crashed varnishd, because then `varnishadm` doesn`t work. So test your syntax before reloading/restart.

* do you want to get rid off old loads from vcl.list? `varnishadm vcl.discard katiska-orig`

## When panicking

There is two way to handle situations when something goes to south.

**Varnish is up** but it is doing something it should not, like caching admin-side of a backend or giving some error to users. Then it easier warm up `emergency.vcl`. All it does is giving to everyone `return(pipe)` and letting everyone directly thru.
```
varnishadm vcl.use emergency
```
Make your fixed, load them up and return back to business changing back to ordinary:
```
varnishadm vcl.use root
```

**Varnish** has crashed, because you didn't check if a VCL has error, or something else. We must start `varnishd` to get CLI, and easier way to do that fast is using panicbutton:
```
./panic.sh
```
* the script starts new `varnishd`
* it uses `start.cli.emerg`
* and that loads up and uses `emergency.vcl`

Because all of that happens in CLI your `varnishd` shuts down when you close CLI session. So perhaps new console and there tmux is a smart move?

## My opinion

This is one solution when using multiple hosts. But lack of `systemctl reload varnish` makes it a bit handful for amateurs. I must say that after quite short while load/labe route is better option, soecially when using aliasses of bash. Perhaps using https://github.com/eksiscloud/Varnish_7.x/blob/main/default.vcl is another option - but then you **must** fix all sub vcls. These here are basically same, but all? stupid errors and unlogical things are fixed now.

