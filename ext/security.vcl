sub sec_headers {

	### These should come from apps and/or server, but like WordPress doesn't set anything
	### For me this is easier solution because now I can handle everything in one place
	### Everything here works only if not piped. So, Discourse can't be secured here - there is no need, though, becauce Discourse sets these up by itself

	## Cross Site Scripting, aka. XSS
	if (!resp.http.X-XSS-Protection) {
		set resp.http.X-XSS-Protection = "1; mode=block";
	}
	
	## Content Security Policy, aka. CSP
	# Use your browser to find out if (or when...) there is some CSP violations by the rules
	# or set up reporting endpoint
	
	# Applies only if a backend doesn't set CSP; if CSP or another headers come from frontend, like proxy as Nginx, Varnish doesn't see it
	if (!resp.http.Content-Security-Policy) {
		
		## I'm using temporary rules to help reading/tuning/fixing
		
		# Google is using solution that rapes CSP big time. I could ban almost everything from www.google.* and adservice.google.* because my sites are pure finnish
		set resp.http.x-www-google = "www.google.co.jp www.google.com.mt www.google.com.ar www.google.co.za www.google.lt www.google.co.nz www.google.cz www.google.mk www.google.pl www.google.be www.google.ie www.google.ch www.google.dk www.google.ae www.google.hu www.google.fr www.google.at www.google.gr www.google.com.cy www.google.ee www.google.ca www.google.it www.google.hr www.google.lv www.google.co.uk www.google.nl www.google.com.au www.google.es www.google.no www.google.se www.google.de www.google.fi www.google.com";
		set resp.http.x-adservice = "adservice.google.co.jp adservice.google.com.mt adservice.google.com.ar adservice.google.co.za adservice.google.lt adservice.google.co.nz adservice.google.cz adservice.google.mk adservice.google.pl adservice.google.be adservice.google.ie adservice.google.ch adservice.google.dk adservice.google.ae adservice.google.hu adservice.google.fr adservice.google.at adservice.google.gr adservice.google.com.cy adservice.google.ee adservice.google.ca adservice.google.it adservice.google.hr adservice.google.lv adservice.google.co.uk adservice.google.com adservice.google.pt adservice.google.com.au adservice.google.nl adservice.google.fi adservice.google.se adservice.google.no adservice.google.it adservice.google.es adservice.google.de";
		
		# Common parts
		set resp.http.x-base-uri = "base-uri 'self'; ";	# Not in hosts
		set resp.http.x-child-src = "child-src apis.google.com 'self'";
		set resp.http.x-script-src = "script-src 'unsafe-eval' 'unsafe-inline' 'self' data: stats.eksis.eu/matomo.js connect.facebook.net use.fontawesome.com stats.eksis.eu seuranta.eksis.pro www.googletagservices.com www.googletagmanager.com www.gstatic.com www.google-analytics.com";		# If you are using WordPress and/or any services from Google avoiding 'unsafe-inline' is nearly impossible
		set resp.http.x-script-src-elem = "script-src-elem 'unsafe-eval' 'unsafe-inline' 'self' data: stats.eksis.eu/matomo.js connect.facebook.net use.fontawesome.com seuranta.eksis.pro www.googletagservices.com www.googletagmanager.com www.gstatic.com www.google-analytics.com";	# some browsers, like Safari and security parts from Firefox, have difficulties fall back to script-src
		set resp.http.x-script-src-attr = "script-src-attr 'unsafe-inline' 'self'";
		set resp.http.x-connect-src = "connect-src attestation.android.com csi.gstatic.com www.gstatic.com www.google-analytics.com stats.eksis.eu seuranta.eksis.pro 'self'";
		set resp.http.x-frame-src = "frame-src web.facebook.com www.facebook.com www.youtube.com www.google.com stats.eksis.eu 'self'";
		set resp.http.x-img-src = "img-src commons.wikimedia.org www.facebook.com secure.gravatar.com www.gstatic.com www.googletagmanager.com www.google-analytics.com stats.eksis.eu data: 'self'";
		set resp.http.x-media-src = "media-src 'self'";
		set resp.http.x-font-src = "font-src static3.avast.com/1000947/web/o/f/ use.fontawesome.com fonts.gstatic.com data: 'self'";
		set resp.http.x-style-src = "style-src www.gstatic.com translate.googleapis.com use.fontawesome.com cdnjs.cloudflare.com connect.facebook.net 'unsafe-inline' 'self'";
		set resp.http.x-object-src = "object-src 'self'; ";	# Not in hosts
		set resp.http.x-form-action = "form-action 'self'";
		set resp.http.x-prefetch-src = "prefetch-src l.facebook.com 'self'";
		set resp.http.x-manifest-src = "manifest-src 'self'";
		set resp.http.x-frame-ancestors = "frame-ancestors stats.eksis.eu 'self'";
		set resp.http.x-worker-src = "worker-src blob:";
		#set resp.http.x-sandbox = "sandbox allow-scripts" + "; ";
		set resp.http.x-upgrade-mixed = "upgrade-insecure-requests; block-all-mixed-content;";
		set resp.http.x-report = "report-uri https://" + req.http.host + "/_csp;";	# not defined in hosts unless different
		
		
		# Host based parts
		
		# WordPress
		if (req.http.host ~ "www.katiska.eu") {
			set resp.http.x-csp-host = "www.katiska.eu cdn.katiska.eu store.katiska.eu cdnstore.katiska.eu selko.katiska.eu";
			set resp.http.x-child-src = resp.http.x-child-src + " " + "*.youtube.com stats.g.doubleclick.net" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src = resp.http.x-script-src + " " + "cdn.jsdelivr.net platform.twitter.com bam.nr-data.net js-agent.newrelic.com cdnjs.cloudflare.com cdn.mxpnl.com fast.wistia.com beacon-v2.helpscout.net cdn.ampproject.org stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-elem = resp.http.x-script-src-elem + " " + "bam.nr-data.net js-agent.newrelic.com/nr-1210.min.js cdn.ampproject.org cdn.mxpnl.com/libs/mixpanel-2-latest.min.js fast.wistia.com beacon-v2.helpscout.net stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-attr = resp.http.x-script-src-attr + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-connect-src = resp.http.x-connect-src + " " + "stats.g.doubleclick.net d3hb14vkzrxvla.cloudfront.net endpoint1.collection.us2.sumologic.com bam.nr-data.net fg8vvsvnieiv3ej16jby.litix.io api-js.mixpanel.com embed-fastly.wistia.com embedwistia-a.akamaihd.net distillery.wistia.com pipedream.wistia.com beaconapi.helpscout.net beacon-v2.helpscout.net fast.wistia.com attestation.android.com stats.g.doubleclick.net pagead2.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-src = resp.http.x-frame-src + " " + "fi.wordpress.org wp.freemius.com pagead2.googlesyndication.com googleads.g.doubleclick.net stats.g.doubleclick.net tpc.googlesyndication.com data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-img-src = resp.http.x-img-src + " " + "mailster.co/wp-content/uploads/2021/08/plugin-header-256x256.png jasn.asnjournals.org/math/ge.gif www.sciencedirect.com static.xx.fbcdn.net yle.fi www.artstation.com/assets/favicon-1f6ac315d6fdb583078f085998d317e3.ico csi.gstatic.com www.hs.fi pbs.twimg.com ps.w.org www.kennelrehu.fi/media/favicon/default/favicon.ico sporttimekka.fi/sm_favicon.ico www.yliopistonapteekki.fi s.w.org upload.wikimedia.org *.static.flickr.com dashboard.freemius.com img.freemius.com s0.wp.com www.facebook.com secure.gravatar.com deliciousbrains.com fast.wistia.com embed-fastly.wistia.com wp-rocket.me embedwistia-a.akamaihd.net i.ytimg.com syndication.twitter.com platform.twitter.com translate.google.com play-lh.googleusercontent.com pagead2.googlesyndication.com meta-katiska.s3.dualstack.eu-north-1.amazonaws.com blob: data: " + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-media-src = resp.http.x-media-src + " " + "fast.wistia.net e-matsku.s3-eu-west-1.amazonaws.com s3-eu-west-1.amazonaws.com/e-matsku/ blob: data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-font-src = resp.http.x-font-src + " " + "maxcdn.bootstrapcdn.com l.facebook.com themes.googleusercontent.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-style-src = resp.http.x-style-src + " " + "maxcdn.bootstrapcdn.com code.jquery.com deliciousbrains.com ajax.googleapis.com fonts.googleapis.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-form-action = resp.http.x-form-action + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-prefetch-src = resp.http.x-prefetch-src + " " + "www.ncbi.nlm.nih.gov www.researchgate.net/profile/ palvelut2.evira.fi www.koiranravitsemus.fi pagead2.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-manifest-src = resp.http.x-manifest-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-ancestors = resp.http.x-frame-ancestors + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-worker-src = resp.http.x-worker-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
			set resp.http.x-report = "report-uri https://d7e4fdbeb99183fcd925c7a506215cc7.report-uri.com/r/d/csp/enforce;";
		}
		
		# WooCommerce
		# commented, because I'm using return(pipe)
		#elseif (req.http.host ~ "store.katiska.eu") {
		#	set resp.http.x-csp-host = "store.katiska.eu cdnstore.katiska.eu www.katiska.eu cdn.katiska.eu";
		#	set resp.http.x-child-src = resp.http.x-child-src + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src = resp.http.x-script-src + " " + "cdn.jsdelivr.net js.klarna.com cdn.mxpnl.com" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src-elem = resp.http.x-script-src-elem + " " + "bam.nr-data.net js-agent.newrelic.com/nr-1210.min.js cdn.mxpnl.com/libs/mixpanel-2-latest.min.js cdn.jsdelivr.net js.klarna.com cdn.mxpnl.com" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src-attr = resp.http.x-script-src-attr + "; ";
		#	set resp.http.x-connect-src = resp.http.x-connect-src + " " + "embed-fastly.wistia.com embedwistia-a.akamaihd.net app.getsentry.com api-js.mixpanel.com eu.klarnaevt.com" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-frame-src = resp.http.x-frame-src + " " + "fi.wordpress.org js.klarna.com" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-img-src = resp.http.x-img-src + " " + "blob: 'unsafe-inline' i.ytimg.com ps.w.org woopos.com.au cdn.klarna.com eu.klarnaevt.com s3-eu-west-1.amazonaws.com/krokedil-checkout-addons/images/kco/klarna-icon-thumbnail.jpg woocommerce.com woothemess3.s3.amazonaws.com deliciousbrains.com" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-media-src = resp.http.x-media-src + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-font-src = resp.http.x-font-src + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-style-src = resp.http.x-style-src + " " + "code.jquery.com deliciousbrains.com ajax.googleapis.com fonts.googleapis.com 'unsafe-inline'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-form-action = resp.http.x-form-action + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-prefetch-src = resp.http.x-prefetch-src + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-manifest-src = resp.http.x-manifest-src + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-frame-ancestors = resp.http.x-frame-ancestors + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-worker-src = resp.http.x-worker-src + "; ";
		#	set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
		#}
				
		# WordPress
		if (req.http.host ~ "selko.katiska.eu") {
			set resp.http.x-csp-host = "selko.katiska.eu www.katiska.eu cdn.katiska.eu meta.katiska.eu cdnmeta.katiska.eu store.katiska.eu cdnstore.katiska.eu";
			set resp.http.x-child-src = resp.http.x-child-src + " " + "*.youtube.com stats.g.doubleclick.net" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src = resp.http.x-script-src + " " + "cdn.jsdelivr.net bam.nr-data.net cdnjs.cloudflare.com cdn.mxpnl.com fast.wistia.com beacon-v2.helpscout.net cdn.ampproject.org stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-elem = resp.http.x-script-src-elem + " " + "bam.nr-data.net cdn.ampproject.org/rtv/012108100143000/amp4ads-host-v0.js beacon-v2.helpscout.net fast.wistia.com cdn.mxpnl.com/libs/mixpanel-2-latest.min.js stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-attr = resp.http.x-script-src-attr + "; ";
			set resp.http.x-connect-src = resp.http.x-connect-src + " " + "stats.g.doubleclick.net d3hb14vkzrxvla.cloudfront.net endpoint1.collection.us2.sumologic.com bam.nr-data.net fg8vvsvnieiv3ej16jby.litix.io api-js.mixpanel.com distillery.wistia.com pipedream.wistia.com beaconapi.helpscout.net beacon-v2.helpscout.net fast.wistia.com attestation.android.com stats.g.doubleclick.net pagead2.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-src = resp.http.x-frame-src + " " + "fi.wordpress.org wp.freemius.com wp-rocket.me accounts.google.com pagead2.googlesyndication.com googleads.g.doubleclick.net stats.g.doubleclick.net apis.google.com tpc.googlesyndication.com data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-img-src = resp.http.x-img-src + " " + "blob: csi.gstatic.com www.hs.fi pbs.twimg.com ps.w.org www.kennelrehu.fi/media/favicon/default/favicon.ico sporttimekka.fi/sm_favicon.ico www.yliopistonapteekki.fi s.w.org upload.wikimedia.org *.static.flickr.com dashboard.freemius.com img.freemius.com s0.wp.com www.facebook.com secure.gravatar.com deliciousbrains.com fast.wistia.com embed-fastly.wistia.com wp-rocket.me embedwistia-a.akamaihd.net i.ytimg.com syndication.twitter.com platform.twitter.com translate.google.com play-lh.googleusercontent.com pagead2.googlesyndication.com meta-katiska.s3.dualstack.eu-north-1.amazonaws.com data:" + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-media-src = resp.http.x-media-src + " " + "embed-fastly.wistia.com embedwistia-a.akamaihd.net fast.wistia.net e-matsku.s3-eu-west-1.amazonaws.com s3-eu-west-1.amazonaws.com/e-matsku/ blob: data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-font-src = resp.http.x-font-src + " " + "maxcdn.bootstrapcdn.com l.facebook.com themes.googleusercontent.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-style-src = resp.http.x-style-src + " " + "maxcdn.bootstrapcdn.com code.jquery.com deliciousbrains.com ajax.googleapis.com fonts.googleapis.com 'unsafe-inline'" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-form-action = resp.http.x-form-action + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-prefetch-src = resp.http.x-prefetch-src + " " + "" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-manifest-src = resp.http.x-manifest-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-ancestors = resp.http.x-frame-ancestors + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-worker-src = resp.http.x-worker-src + "; ";
			set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
		}
		
		# WordPress
		elseif (req.http.host ~ "www.eksis.one") {
			set resp.http.x-csp-host = "www.eksis.one cdn.eksis.one";
			set resp.http.x-child-src = resp.http.x-child-src + " " + "stats.g.doubleclick.net" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src = resp.http.x-script-src + " " + "gist.github.com cdn.jsdelivr.net platform.twitter.com bam.nr-data.net js-agent.newrelic.com cdnjs.cloudflare.com cdn.mxpnl.com fast.wistia.com beacon-v2.helpscout.net cdn.ampproject.org stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-elem = resp.http.x-script-src-elem + " " + "gc.kis.v2.scr.kaspersky-labs.com/FD126C42-EBFA-4E12-B309-BB3FDD723AC1/main.js bam.nr-data.net js-agent.newrelic.com/nr-1210.min.js cdn.ampproject.org/rtv/012108100143000/amp4ads-host-v0.js beacon-v2.helpscout.net fast.wistia.com gist.github.com cdn.mxpnl.com/libs/mixpanel-2-latest.min.js stats.g.doubleclick.net partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-attr = resp.http.x-script-src-attr + "; ";
			set resp.http.x-connect-src = resp.http.x-connect-src + " " + "stats.g.doubleclick.net d3hb14vkzrxvla.cloudfront.net embed-fastly.wistia.com embedwistia-a.akamaihd.net endpoint1.collection.us2.sumologic.com bam.nr-data.net fg8vvsvnieiv3ej16jby.litix.io api-js.mixpanel.com distillery.wistia.com pipedream.wistia.com beaconapi.helpscout.net beacon-v2.helpscout.net fast.wistia.com attestation.android.com stats.g.doubleclick.net pagead2.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-src = resp.http.x-frame-src + " " + "w.soundcloud.com fi.wordpress.org wp.freemius.com wp-rocket.me pagead2.googlesyndication.com googleads.g.doubleclick.net stats.g.doubleclick.net tpc.googlesyndication.com data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-img-src = resp.http.x-img-src + " " + "blob: s.w.org/images/core/emoji/ s.w.org/plugins/ csi.gstatic.com w.soundcloud.com pbs.twimg.com ps.w.org dashboard.freemius.com img.freemius.com s0.wp.com www.facebook.com secure.gravatar.com deliciousbrains.com fast.wistia.com embed-fastly.wistia.com wp-rocket.me embedwistia-a.akamaihd.net i.ytimg.com syndication.twitter.com platform.twitter.com translate.google.com play-lh.googleusercontent.com pagead2.googlesyndication.com" + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-media-src = resp.http.x-media-src + " " + "fast.wistia.net data:" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-font-src = resp.http.x-font-src + " " + "maxcdn.bootstrapcdn.com l.facebook.com themes.googleusercontent.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-style-src = resp.http.x-style-src + " " + "github.githubassets.com maxcdn.bootstrapcdn.com code.jquery.com deliciousbrains.com ajax.googleapis.com fonts.googleapis.com 'unsafe-inline'" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-form-action = resp.http.x-form-action + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-prefetch-src = resp.http.x-prefetch-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-manifest-src = resp.http.x-manifest-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-ancestors = resp.http.x-frame-ancestors + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-worker-src = resp.http.x-worker-src + "; ";
			set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
		}
				
		# WordPress
		if (req.http.host ~ "jagster.eksis.one") {
			set resp.http.x-csp-host = "jagster.eksis.one www.katiska.eu cdn.katiska.eu";
			set resp.http.x-child-src = resp.http.x-child-src + " " + "stats.g.doubleclick.net" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src = resp.http.x-script-src + " " + "cdn.jsdelivr.net bam.nr-data.net js-agent.newrelic.com cdnjs.cloudflare.com cdn.mxpnl.com fast.wistia.com beacon-v2.helpscout.net stats.g.doubleclick.net cdn.ampproject.org partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com 'unsafe-eval'" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-elem = resp.http.x-script-src-elem + " " + "cdnjs.cloudflare.com/ajax/libs/jquery-modal/0.9.1/jquery.modal.min.js platform.twitter.com/widgets.js bam.nr-data.net js-agent.newrelic.com/nr-1210.min.js cdn.ampproject.org/rtv/012108100143000/amp4ads-host-v0.js beacon-v2.helpscout.net fast.wistia.com cdn.mxpnl.com/libs/mixpanel-2-latest.min.js stats.g.doubleclick.net cdn.ampproject.org partner.googleadservices.com tpc.googlesyndication.com pagead2.googlesyndication.com apis.google.com ajax.googleapis.com 'unsafe-eval'" + " " + resp.http.x-adservice + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-script-src-attr = resp.http.x-script-src-attr + "; ";
			set resp.http.x-connect-src = resp.http.x-connect-src + " " + "stats.g.doubleclick.net d3hb14vkzrxvla.cloudfront.net embed-fastly.wistia.com embedwistia-a.akamaihd.net endpoint1.collection.us2.sumologic.com bam.nr-data.net fg8vvsvnieiv3ej16jby.litix.io api-js.mixpanel.com distillery.wistia.com pipedream.wistia.com beaconapi.helpscout.net beacon-v2.helpscout.net fast.wistia.com attestation.android.com stats.g.doubleclick.net pagead2.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-src = resp.http.x-frame-src + " " + "player.vimeo.com fi.wordpress.org wp.freemius.com wp-rocket.me pagead2.googlesyndication.com googleads.g.doubleclick.net stats.g.doubleclick.net tpc.googlesyndication.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-img-src = resp.http.x-img-src + " " + "www.imagely.com/wp-content/uploads/2020/06/ www.hooks.fi paivolantila.mycashflow.fi/product/63/virikepallo www.kuntonetti.org mobile.twitter.com twitter.com www.instagram.com csi.gstatic.com f001.backblazeb2.com/file/ f001.backblaze.com/file/nextgen-gallery/ pbs.twimg.com ps.w.org s.w.org dashboard.freemius.com img.freemius.com s0.wp.com www.facebook.com secure.gravatar.com deliciousbrains.com fast.wistia.com embed-fastly.wistia.com wp-rocket.me embedwistia-a.akamaihd.net i.ytimg.com syndication.twitter.com platform.twitter.com play-lh.googleusercontent.com pagead2.googlesyndication.com blob: 'unsafe-inline'" + " " + resp.http.x-www-google + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-media-src = resp.http.x-media-src + " " + "s3-eu-west-1.amazonaws.com/e-matsku/julkiset/pod/sokea_piste/ fast.wistia.net" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-font-src = resp.http.x-font-src + " " + "maxcdn.bootstrapcdn.com l.facebook.com themes.googleusercontent.com" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-style-src = resp.http.x-style-src + " " + "maxcdn.bootstrapcdn.com code.jquery.com deliciousbrains.com ajax.googleapis.com fonts.googleapis.com 'unsafe-inline'" + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-form-action = resp.http.x-form-action + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-prefetch-src = resp.http.x-prefetch-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-manifest-src = resp.http.x-manifest-src + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-frame-ancestors = resp.http.x-frame-ancestors + " " + resp.http.x-csp-host + "; ";
			set resp.http.x-worker-src = resp.http.x-worker-src + "; ";
			set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
		}
				
		# Matomo
		# Commented, because I'm using return(pipe)
		#if (req.http.host ~ "stats.eksis.eu") {
		#	set resp.http.x-csp-host = "stats.eksis.eu";
		#	set resp.http.x-child-src = "child-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src = "script-src 'unsafe-eval' 'unsafe-inline' 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src-elem = "script-src-elem 'unsafe-eval' 'unsafe-inline' 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-script-src-attr = resp.http.x-script-src-attr + "; ";
		#	set resp.http.x-connect-src = "connect-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-frame-src = "frame-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-img-src = "img-src plugins.matomo.org 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-media-src = "media-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-font-src = "font-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-style-src = "style-src 'unsafe-inline' 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-form-action = "form-action 'self'" + "; ";
		#	set resp.http.x-prefetch-src = "prefetch-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-manifest-src = "manifest-src 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-frame-ancestors = "frame-ancestors www.katiska.eu www.eksis.one selko.katiska.eu 'self'" + " " + resp.http.x-csp-host + "; ";
		#	set resp.http.x-worker-src = resp.http.x-worker-src + "; ";
		#	set resp.http.x-upgrade-mixed = resp.http.x-upgrade-mixed + " ";
		#}
		
		# Common fallback to everything
		set resp.http.x-default-src = "default-src 'self'; ";
		
		# CSP parsing
		# if you want no action, intel only: resp.http.Content-Security-Policy-Report-Only
		set resp.http.Content-Security-Policy = resp.http.x-default-src + resp.http.x-base-uri + resp.http.x-child-src + resp.http.x-script-src + resp.http.x-script-src-elem + resp.http.x-script-src-attr + resp.http.x-connect-src + resp.http.x-frame-src + resp.http.x-img-src + resp.http.x-media-src + resp.http.x-font-src + resp.http.x-style-src + resp.http.x-object-src + resp.http.x-form-action + resp.http.x-prefetch-src + resp.http.x-manifest-src + resp.http.x-frame-ancestors + resp.http.x-worker-src + resp.http.x-upgrade-mixed + resp.http.x-report;	# + resp.http.x-sandbox 
		
		# Some hosts may not be here, even should
		if (!resp.http.x-csp-host) {
			unset resp.http.Content-Security-Policy;
		}
		
		# I have too many issues with Safari so I don't use acting CSP with WooCommerce - The issues are mostly with embeds
		# Heads up: Safari caches even CSP.
		if (req.http.User-Agent ~ "Safari" && req.http.host ~ "store.") {
			set resp.http.Content-Security-Policy-Report-Only = resp.http.Content-Security-Policy;
			unset resp.http.Content-Security-Policy;
		}
		
		# Remove temps
		unset resp.http.x-www-google;
		unset resp.http.x-default-src;
		unset resp.http.x-base-uri;
		unset resp.http.x-child-src;
		unset resp.http.x-adservice;
		unset resp.http.x-script-src;
		unset resp.http.x-script-src-elem;
		unset resp.http.x-script-src-attr;
		unset resp.http.x-connect-src;
		unset resp.http.x-frame-src;
		unset resp.http.x-img-src;
		unset resp.http.x-media-src;
		unset resp.http.x-font-src;
		unset resp.http.x-style-src;
		unset resp.http.x-object-src;
		unset resp.http.x-form-action;
		unset resp.http.x-prefetch-src;
		unset resp.http.x-manifest-src;
		unset resp.http.x-frame-ancestors;
		unset resp.http.x-worker-src;
		#unset resp.http.x-sandbox;
		unset resp.http.x-upgrade-mixed;
		unset resp.http.x-report;
		unset resp.http.x-csp-host;
	
	# The end of CSP
	}
	
	## HTTP Strict Transport Security, aka. HSTS
	# Applies only if a backend doesn't set HSTS as it normally doesn't; if it comes from frontend, like proxy as Nginx, Varnish doesn't see it
	if (!resp.http.Strict-Transport-Security) {
		set resp.http.Strict-Transport-Security = "max-age=31536000; includeSubdomains; ";
	}

	## MIME sniffing
	# Applies only if a backend doesn't set sniffing as it normally doesn't; if it comes from frontend, like proxy as Nginx, Varnish doesn't see it
	if (!resp.http.X-Content-Type-Options) {
		set resp.http.X-Content-Type-Options = "nosniff";
	}
	
	## Referrer-Policy
	if (!resp.http.Referrer-Policy) {
		set resp.http.Referrer-Policy = "strict-origin-when-cross-origin";
	}
	
	# I have some embed issues and I need full referring url
	if (req.http.host ~ "katiska.info") {
		set resp.http.Referrer-Policy = "unsafe-url";
	}
	
	# Remove X-Frame-Optios if CSP is in use
	if (resp.http.Content-Security-Policy) {
		unset resp.http.X-Frame-Options;
	}
	# Add X-Frame.Options if both are missing
	elseif (!resp.http.Content-Security-Policy && !resp.http.X-Frame-Options) {
		set resp.http.X-Frame-Options = "sameorigin";
	}
	
	## Cleaning unnecessary headers
	if (resp.http.obj ~ "\.(appcache|atom|bbaw|bmp|crx|css|cur|eot|f4[abpv]|flv|geojson|gif|htc|ic[os]|jpe?g|m?js|json(ld)?|m4[av]|manifest|map|markdown|md|mp4|oex|og[agv]|opus|otf|pdf|png|rdf|rss|safariextz|svgz?|swf|topojson|tt[cf]|txt|vcard|vcf|vtt|webapp|web[mp]|webmanifest|woff2?|xloc|xpi)$") {
		unset resp.http.X-UA-Compatible;
		unset resp.http.X-XSS-Protection;
	}
	
	if (resp.http.obj ~ "\.(appcache|atom|bbaw|bmp|crx|css|cur|eot|f4[abpv]|flv|geojson|gif|htc|ic[os]|jpe?g|json(ld)?|m4[av]|manifest|map|markdown|md|mp4|oex|og[agv]|opus|otf|png|rdf|rss|safariextz|swf|topojson|tt[cf]|txt|vcard|vcf|vtt|webapp|web[mp]|webmanifest|woff2?|xloc|xpi)$") {
		unset resp.http.Content-Security-Policy;
	}
	
	## Cookies
	# Cookies can be done, manipulated and changed using Varnish. But I can't.
	# Instead manipulation here these should be in wp-config.php of WordPress:
	# @ini_set('session.cookie_httponly', true); 
	# @ini_set('session.cookie_secure', true); 
	# @ini_set('session.use_only_cookies', true);
	
# the end of the sub
}
