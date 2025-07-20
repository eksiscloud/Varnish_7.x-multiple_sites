sub bad_bot_detection {

#### Not in use

## I have to set user agent to find out in 404 monitoring of Wordpress who is getting 404.
## So, I'll store user agent in X-User-Agent and it will be restored after hashing.
##
## There is no point what so ever to start fixing 404s made by bots and harvesters
## Fix only real things that are issues for users and Google etc.
##
## All these have been visited or are still trying to my sites.
## Shows 404s: awk '($9 ~ /404/)' /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -rn
## Shows user agents: awk -F'"' '/GET/ {print $6}' /var/log/nginx/access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn
#
# True bots, spiders and harvesters; Rogues, keyword harvesting and useless SEO
# These are mostly handled by Nginx giving error 444
# So, this vcl is more or less just backup. 
#
# Just using ($server_protocol = HTTP/1.0) { return 444; } in Nginx blocks plenty of these

	if (
		   req.http.User-Agent == "^$"							# Nginx is passing these two
		|| req.http.User-Agent == "-"							# because I couldn't success with LUA
		# #
		|| req.http.User-Agent ~ "360Spider"					# bad 		- done
		|| req.http.User-Agent ~ "2345Explorer"					# malicious - done
		# A 
		|| req.http.User-Agent ~ "Acast "						# bad 		- done
		|| req.http.User-Agent ~ "Accept-Encoding"
		|| req.http.User-Agent ~ "AccompanyBot"
		|| req.http.User-Agent ~ "AdAuth"						# bad 		- done
		|| req.http.User-Agent ~ "adidxbot"						# good
		|| req.http.User-Agent ~ "admantx"						# bad 		- done
		|| req.http.User-Agent ~ "Adsbot/"
		|| req.http.User-Agent ~ "AdsTxtCrawler"				# bad 		- done
		|| req.http.User-Agent ~ "AffiliateLabz"				# good 		- done
		|| req.http.User-Agent ~ "AHC"							# malicious
		|| req.http.User-Agent ~ "AhrefsBot"					# good		- done
		|| req.http.User-Agent ~ "aiohttp"
		|| req.http.User-Agent ~ "akka-http/"					# malicious - done
		|| req.http.User-Agent ~ "ALittle"
		|| req.http.User-Agent ~ "Amazon-Advertising-ad-standards-bot"
                || req.http.User-Agent ~ "Amazonbot"
		|| req.http.User-Agent ~ "AmazonAdBot"
		|| req.http.User-Agent ~ "Amazon CloudFront"			# malicious - done
		|| req.http.User-Agent == "AmazonMusic"
		|| req.http.User-Agent ~ "amp-wp"
		|| req.http.User-Agent ~ "Anarchy99"
		|| req.http.User-Agent ~ "Anchorage DMP"				# bad		- done
		|| req.http.User-Agent ~ "AndroidDownloadManager"
		|| req.http.User-Agent ~ "Apache-HttpClient"			# malicious - done
		|| req.http.User-Agent ~ "Apache-CXF"
		|| req.http.User-Agent ~ "ApiTool"
		|| req.http.User-Agent ~ "Aranea"
		|| req.http.User-Agent ~ "aria2"
		|| req.http.User-Agent ~ "Asana"
		|| req.http.User-Agent ~ "AspiegelBot"					# good
		|| req.http.User-Agent ~ "Audacy-Podcast-Scraper"
		|| req.http.User-Agent ~ "AudigentAdBot"
		|| req.http.User-Agent ~ "AudioNow"						# https://audionow.de/
		|| req.http.User-Agent ~ "AvocetCrawler"
		|| req.http.User-Agent ~ "AVSearch"
		|| req.http.User-Agent ~ "AwarioBot"					# brand/marketing
		|| req.http.User-Agent ~ "AwarioRssBot"					# brand/marketing - done
		|| req.http.User-Agent ~ "AwarioSmartBot"				# brand/marketing - done
		|| req.http.User-Agent ~ "axios"						# bad
		# B
		|| req.http.User-Agent ~ "Baidu"
		|| req.http.User-Agent ~ "BacklinksExtendedBot"
		|| req.http.User-Agent ~ "Barkrowler"
		|| req.http.User-Agent ~ "BDCbot"
		|| req.http.User-Agent ~ "bidswitchbot"					# bad
		|| req.http.User-Agent ~ "Bidtellect"
		|| req.http.User-Agent ~ "BlackBerry"
		|| req.http.User-Agent ~ "Blackboard Safeassign"
		|| req.http.User-Agent ~ "BLEXBot"
		|| req.http.User-Agent ~ "Bloglines"
		|| req.http.User-Agent ~ "BorneoBot"
		|| req.http.User-Agent ~ "botify"
		|| req.http.User-Agent ~ "Buck"							# bad
		|| req.http.User-Agent ~ "BuiltWith"
		|| req.http.User-Agent ~ "Bullhorn"
		|| req.http.User-Agent ~ "BW/"
		|| req.http.User-Agent ~ "Bytespider"
		# C
		|| req.http.User-Agent ~ "CarrierWave"
		|| req.http.User-Agent ~ "CatchBot"
		|| req.http.User-Agent ~ "CATExplorador"				# bad
		|| req.http.User-Agent ~ "CCBot"						# bad
		|| req.http.User-Agent ~ "CensysInspect"
		|| req.http.User-Agent ~ "Centro"
		|| req.http.User-Agent ~ "check1\.exe"
		|| req.http.User-Agent ~ "check_http/"
		|| req.http.User-Agent ~ "CheckMarkNetwork"
		|| req.http.User-Agent ~ "checkout-"
		|| req.http.User-Agent ~ "CISPA"
		|| req.http.User-Agent ~ "Clarabot"
		|| req.http.User-Agent ~ "Cliqzbot"						# bad
		|| req.http.User-Agent ~ "Clone"
		|| req.http.User-Agent ~ "Cloud mapping experiment"
		|| req.http.User-Agent ~ "CMS Crawler"
		|| req.http.User-Agent ~ "coccocbot"					# bad, uses "normal" UA at same time
		|| req.http.User-Agent ~ "COMODO"
		|| req.http.User-Agent ~ "colly"
		|| req.http.User-Agent ~ "crawler4j"
		|| req.http.User-Agent ~ "Crawling"
		|| req.http.User-Agent ~ "CriteoBot"
		# D
		|| req.http.User-Agent ~ "DataForSeoBot"
		|| req.http.User-Agent ~ "datagnionbot"
		|| req.http.User-Agent ~ "Datanyze"
		|| req.http.User-Agent ~ "Dataprovider"
		|| req.http.User-Agent ~ "Daum"							# bad
		|| req.http.User-Agent ~ "deepcrawl.com"
		|| req.http.User-Agent ~ "^demo$"
		|| req.http.User-Agent ~ "DF Bot"
		|| req.http.User-Agent ~ "digincore"
		|| req.http.User-Agent ~ "Directo-Indexer"
		|| req.http.User-Agent ~ "Disqus"
		|| req.http.User-Agent ~ "Discordbot"
#		|| req.http.User-Agent ~ "DisqusAdstxtCrawler"
		|| req.http.User-Agent ~ "Dispatch"
		|| req.http.User-Agent ~ "DNSResearchBot"
		|| req.http.User-Agent ~ "DomainStatsBot"
		|| req.http.User-Agent ~ "Domnutch"
		|| req.http.User-Agent ~ "DotBot"
		|| req.http.User-Agent ~ "downcast"
		|| req.http.User-Agent ~ "dproxy"
		# E
		|| req.http.User-Agent ~ "eContext"
		|| req.http.User-Agent ~ "Embarcadero"
		|| req.http.User-Agent ~ "EnigmaBot"
		|| req.http.User-Agent ~ "Entale bot"					# bad
		|| req.http.User-Agent ~ "en_NL"
		|| req.http.User-Agent ~ "en-NL"
		|| req.http.User-Agent ~ "en-US\)"
		|| req.http.User-Agent ~ "e.ventures"
		|| req.http.User-Agent ~ "Exabot"
		|| req.http.User-Agent ~ "excon"
		|| req.http.User-Agent ~ "Expance"
		|| req.http.User-Agent ~ "expanseinc"
		|| req.http.User-Agent ~ "Ezooms"
		|| req.http.User-Agent ~ "evc-batch"
		|| req.http.User-Agent ~ "ev-crawler"		
		# F
#		|| req.http.User-Agent ~ "Facebot Twitterbot"			# When legit it is preview of Apple devices
		|| req.http.User-Agent ~ "fediversecounter"			# too keen mastodon.social
		|| req.http.User-Agent ~ "Faraday"
		|| req.http.User-Agent ~ "Foregenix"
		|| req.http.User-Agent ~ "fr-crawler"
		|| req.http.User-Agent ~ "FYEO"
		|| req.http.User-Agent ~ "fyeo-crawler"
		# G
		|| req.http.User-Agent ~ "GarlikCrawler"
		|| req.http.User-Agent ~ "GeedoProductSearch"
		|| req.http.User-Agent ~ "GenomeCrawlerd"
		|| req.http.User-Agent ~ "GetIntent"
		|| req.http.User-Agent ~ "GetPodcast"
		|| req.http.User-Agent ~ "GigablastOpenSource"
		|| req.http.User-Agent ~ "gdnplus"
		|| req.http.User-Agent ~ "gobyus"
		|| req.http.User-Agent ~ "Go-http-client"				# bad, the most biggest issue and mostly from China and arabic countries
		|| req.http.User-Agent ~ "^got "
		|| req.http.User-Agent ~ "GotSiteMonitor"
		|| req.http.User-Agent ~ "GrapeshotCrawler"				# bad
		|| req.http.User-Agent ~ "GRequests"
		|| req.http.User-Agent ~ "GT-C3595"
		|| req.http.User-Agent ~ "GuzzleHttp"
		# H
		|| req.http.User-Agent ~ "hackney"
		|| req.http.User-Agent ~ "Hello"
		|| req.http.User-Agent ~ "heritrix"
		|| req.http.User-Agent ~ "HotJava"
		|| req.http.User-Agent ~ "htInEdin"
		|| req.http.User-Agent ~ "HTTP Banner Detection"
		#|| req.http.User-Agent ~ "http.rb"
		|| req.http.User-Agent ~ "httpx"
		|| req.http.User-Agent ~ "hu_HU"
		|| req.http.User-Agent ~ "hubspot"
		|| req.http.User-Agent ~ "HubSpot"
		# I
		|| req.http.User-Agent ~ "IAB ATQ"
		|| req.http.User-Agent ~ "IAB-Tech-Lab"
		|| req.http.User-Agent ~ "IAS crawler"					# bad
		|| req.http.User-Agent ~ "ias-"							# bad
		|| req.http.User-Agent ~ "Iframely"
		|| req.http.User-Agent ~ "import.io"
		|| req.http.User-Agent ~ "Incutio"
		|| req.http.User-Agent ~ "INGRID/"
		|| req.http.User-Agent ~ "InfoSeek"
		|| req.http.User-Agent ~ "Inst%C3%A4llningar/"
		|| req.http.User-Agent ~ "internal dummy connection"
		|| req.http.User-Agent ~ "Internet-structure-research-project-bot"
		|| req.http.User-Agent ~ "istellabot"
		|| req.http.User-Agent == "itms"						# Trying to claim to be iTunes
		|| req.http.User-Agent ~ "iVoox"
		# J
		|| req.http.User-Agent ~ "Java/"
		|| req.http.User-Agent ~ "Jersey"						# bad
		|| req.http.User-Agent ~ "Jetty"
		|| req.http.User-Agent ~ "JobboerseBot"
		# K
#		|| req.http.User-Agent ~ "Kik"
		|| req.http.User-Agent ~ "Kinza"
		|| req.http.User-Agent ~ "Knoppix"
		|| req.http.User-Agent ~ "KOCMOHABT"
		|| req.http.User-Agent ~ "Kraphio"
		|| req.http.User-Agent ~ "Kryptos"
		|| req.http.User-Agent ~ "Ktor"
		|| req.http.User-Agent ~ "kubectl"						# malicious
		# L
		|| req.http.User-Agent ~ "l9tcpid"
		|| req.http.User-Agent ~ "l9explore"
		|| req.http.User-Agent ~ "Lavf"
		|| req.http.User-Agent ~ "Leap"
		|| req.http.User-Agent ~ "Leikibot"					# marketing
		|| req.http.User-Agent ~ "Liana"
		|| req.http.User-Agent ~ "LieBaoFast"					# bad
		|| req.http.User-Agent ~ "LightspeedSystemsCrawler"
		|| req.http.User-Agent ~ "Linguee"
		|| req.http.User-Agent ~ "linkdexbot"
#		|| req.http.User-Agent ~ "LinkedInBot"					# bad
		|| req.http.User-Agent ~ "linklooker"
		|| req.http.User-Agent ~ "Linux Gnu"
		|| req.http.User-Agent ~ "ListenNotes"
		|| req.http.User-Agent ~ "ltx71"
		|| req.http.User-Agent ~ "Luminary"
		|| req.http.User-Agent ~ "Lycos"
		# M
		|| req.http.User-Agent ~ "magpie-crawler"
		|| req.http.User-Agent ~ "Mail.RU_Bot"
		|| req.http.User-Agent ~ "masscan"
		|| req.http.User-Agent ~ "MauiBot"
		|| req.http.User-Agent ~ "Mb2345Browser"				# bad
		|| req.http.User-Agent ~ "MegaIndex.ru"
		|| req.http.User-Agent ~ "Mercator"
		|| req.http.User-Agent ~ "MixerBox"
		|| req.http.User-Agent ~ "MixnodeCache"
		|| req.http.User-Agent ~ "MJ12bot"						# good
#		|| req.http.User-Agent ~ "ms-office"
#		|| req.http.User-Agent ~ "MSOffice 16"
#		|| req.http.User-Agent ~ "MojeekBot"
		|| req.http.User-Agent ~ "MOT-"
#		|| req.http.User-Agent ~ "MozacFetch"
		|| req.http.User-Agent ~ "MTRobot"
		|| req.http.User-Agent ~ "MyTuner-ExoPlayerAdapter"
		|| req.http.User-Agent ~ "My User Agent"
		# N
		|| req.http.User-Agent ~ "Needle"
		|| req.http.User-Agent ~ "NetcraftSurveyAgent"			# bad
		|| req.http.User-Agent ~ "netEstate"
		|| req.http.User-Agent ~ "NetPositive"
		|| req.http.User-Agent ~ "NetSeer"
		|| req.http.User-Agent ~ "NetSystemsResearch"
		|| req.http.User-Agent ~ "Nextcloud"
		|| req.http.User-Agent ~ "newspaper"					# python3
		|| req.http.User-Agent ~ "Nimbostratus-Bot"				# bad
		|| req.http.User-Agent ~ "nl_NL"
		|| req.http.User-Agent ~ "nl-NL"
		|| req.http.User-Agent ~ "Nmap Scripting Engine"
		|| req.http.User-Agent ~ "node-fetch"					# malicious
		|| req.http.User-Agent ~ "Nokia5530"
		|| req.http.User-Agent ~ "NokiaN70"
		|| req.http.User-Agent ~ "NRCAudioBot"
		|| req.http.User-Agent ~ "Nutch"
		# O
		|| req.http.User-Agent ~ "oBot"
		|| req.http.User-Agent ~ "observer"
		|| req.http.User-Agent ~ "oncrawl.com"
		|| req.http.User-Agent ~ "Orucast"
		|| req.http.User-Agent ~ "OwlTail"
		# P
		|| req.http.User-Agent ~ "PageThing"
		|| req.http.User-Agent ~ "Pandalytics"
		|| req.http.User-Agent ~ "panscient.com"
		|| req.http.User-Agent ~ "PaperLiBot"
		|| req.http.User-Agent ~ "PCNBrowser"
		|| req.http.User-Agent ~ "peer39_crawler"
		|| req.http.User-Agent ~ "PetalBot"						# same as AspiegelBot
		|| req.http.User-Agent ~ "PhantomJS"
		|| req.http.User-Agent ~ "PHist/"
		|| req.http.User-Agent ~ "Photon/"  					# Automattic
		|| req.http.User-Agent ~ "PHP/"
		|| req.http.User-Agent ~ "PlayerFM"
		|| req.http.User-Agent ~ "pimeyes.com"
		|| req.http.User-Agent ~ "PocketCasts"
		|| req.http.User-Agent ~ "Podalong"
		|| req.http.User-Agent ~ "Podbean"
		|| req.http.User-Agent ~ "PodcastAddict"
		|| req.http.User-Agent ~ "Podcastindex"
		|| req.http.User-Agent ~ "PodcastRepublic"
		|| req.http.User-Agent ~ "PodcastRegion"
		|| req.http.User-Agent ~ "Podchaser"
		|| req.http.User-Agent ~ "Podchaser-Parser"
		|| req.http.User-Agent ~ "Podimo"
		|| req.http.User-Agent ~ "podnods"
		|| req.http.User-Agent ~ "PodParadise"
		|| req.http.User-Agent ~ "Podplay-Podcast-Sync"
		|| req.http.User-Agent ~ "Podscribe"
		|| req.http.User-Agent ~ "Podverse"
		|| req.http.User-Agent ~ "PodvineBot"
		|| req.http.User-Agent ~ "Podyssey"
		|| req.http.User-Agent ~ "Poster"						# malicious
		|| req.http.User-Agent ~ "PR-CY.RU"
		|| req.http.User-Agent ~ "print\("						# malicious
		|| req.http.User-Agent ~ "project-resonance"
		|| req.http.User-Agent ~ "proximic"						# bad, really big issue, mostly from Amazon
		|| req.http.User-Agent ~ "PulsePoint-Ads.txt-Crawler"
		|| req.http.User-Agent ~ "python"
		|| req.http.User-Agent ~ "Python"
		# Q
		||req.http.User-Agent ~ "Quantcastbot"
		|| req.http.User-Agent ~ "Qwantify"
		# R
		|| req.http.User-Agent ~ "R6_"
		|| req.http.User-Agent ~ "Radical-Edward"
		|| req.http.User-Agent ~ "radio.at"
		|| req.http.User-Agent ~ "radio.de"
		|| req.http.User-Agent ~ "radio.dk"
		|| req.http.User-Agent ~ "radio.es"
		|| req.http.User-Agent ~ "radio.fr"
		|| req.http.User-Agent ~ "radio.it"
		|| req.http.User-Agent ~ "radio.net"
		|| req.http.User-Agent ~ "radiofeed"
		|| req.http.User-Agent ~ "RawVoice Generator"
		|| req.http.User-Agent ~ "RedCircle"
		|| req.http.User-Agent ~ "Rephonic"
		|| req.http.User-Agent ~ "RepoLookoutBot"
		|| req.http.User-Agent ~ "Request-Promise"
		|| req.http.User-Agent ~ "RestSharp"
		|| req.http.User-Agent ~ "Riddler"
		|| req.http.User-Agent ~ "RogerBot"
		|| req.http.User-Agent ~ "Roku/"
		|| req.http.User-Agent ~ "Rome Client"
		|| req.http.User-Agent ~ "rss-parser"
		|| req.http.User-Agent ~ "RSSGet"
		# S
		|| req.http.User-Agent ~ "safarifetcherd"
		|| req.http.User-Agent ~ "SafeDNSBot"
		|| req.http.User-Agent ~ "SafetyNet"
		|| req.http.User-Agent ~ "scalaj-http"
		|| req.http.User-Agent ~ "Scooter"
		|| req.http.User-Agent ~ "Scrapy"
		|| req.http.User-Agent ~ "Screaming"
#		|| req.http.User-Agent ~ "SE 2.X MetaSr 1.0"
		|| req.http.User-Agent ~ "SearchAtlas"
		|| req.http.User-Agent ~ "Seekport"
		|| req.http.User-Agent ~ "seewithkids.com"				# good
		|| req.http.User-Agent ~ "SemanticScholarBot"
		|| req.http.User-Agent ~ "SemrushBot"			# bad
		|| req.http.User-Agent ~ "SEMrushBot"
		|| req.http.User-Agent ~ "SEOkicks"
		|| req.http.User-Agent ~ "SEOlizer"
		|| req.http.User-Agent ~ "SerendeputyBot"
		|| req.http.User-Agent ~ "serpstatbot"
		|| req.http.User-Agent ~ "SeznamBot"
		|| req.http.User-Agent ~ "Sidetrade"
		|| req.http.User-Agent ~ "SimplePie"
		|| req.http.User-Agent ~ "SirdataBot"
		|| req.http.User-Agent ~ "SiteBot"
		|| req.http.User-Agent ~ "Slack-ImgProxy"
		|| req.http.User-Agent ~ "Slurp"
		|| req.http.User-Agent ~ "SMTBot"
		|| req.http.User-Agent ~ "Snap URL"						# https://support.article
		|| req.http.User-Agent ~ "Sodes/"						# podcaster IP 209.6.245.67
		|| req.http.User-Agent ~ "Sogou"
		|| req.http.User-Agent ~ "socialmediascanner"
		|| req.http.User-Agent ~ "ssearch_bot"
		|| req.http.User-Agent ~ "SSL Labs"
		|| req.http.User-Agent ~ "Statically-Images"
		|| req.http.User-Agent ~ "SurdotlyBot"					# bad
		|| req.http.User-Agent ~ "Synapse"
		|| req.http.User-Agent ~ "syncify"
		# T
		|| req.http.User-Agent ~ "taddy.org"
		|| req.http.User-Agent ~ "Talous"
		|| req.http.User-Agent ~ "tamarasdartsoss.nl"
		|| req.http.User-Agent ~ "tapai"
#		|| req.http.User-Agent ~ "TelegramBot"
		|| req.http.User-Agent ~ "temnos.com"
		|| req.http.User-Agent ~ "Tentacles"					# bad
		|| req.http.User-Agent ~ "Test Certificate Info"		# malicious
		|| req.http.User-Agent ~ "The Incutio XML-RPC PHP Library"	# malicious
                || req.http.User-Agent ~ "Thinkbot"
		|| req.http.User-Agent ~ "Thumbor"						# bad
		|| req.http.User-Agent ~ "TPA/1.0.0"
		|| req.http.User-Agent ~ "Trade Desk"
		|| req.http.User-Agent ~ "Trade"
		|| req.http.User-Agent ~ "trendictionbot"
		|| req.http.User-Agent ~ "TrendsmapResolver"
		|| req.http.User-Agent ~ "TTD-content"					# bad
		|| req.http.User-Agent ~ "TTD-Content"					# good
		|| req.http.User-Agent ~ "Typhoeus"
		|| req.http.User-Agent ~ "TweetmemeBot"
		|| req.http.User-Agent ~ "Twingly"
		# U
		|| req.http.User-Agent ~ "UCBrowser"
		|| req.http.User-Agent ~ "ucrawl"
		|| req.http.User-Agent ~ "uipbot"
		|| req.http.User-Agent ~ "UltraSeek"
		|| req.http.User-Agent ~ "um-IC"						# bad
		|| req.http.User-Agent ~ "um-LN"
		|| req.http.User-Agent ~ "UMichBot"
		|| req.http.User-Agent ~ "User-Agent"
		|| req.http.User-Agent ~ "UniversalFeedParser"			# bad
		# V
		|| req.http.User-Agent ~ "VelenPublicWebCrawler"
		|| req.http.User-Agent ~ "Verity"
		|| req.http.User-Agent ~ "Viber"
		|| req.http.User-Agent ~ "VLC/"
		# W
		|| req.http.User-Agent ~ "^w3m"
		|| req.http.User-Agent ~ "Wappalyzer"
		|| req.http.User-Agent ~ "weborama-fetcher"
		|| req.http.User-Agent ~ "webprosbot"
		|| req.http.User-Agent ~ "webtech"
		|| req.http.User-Agent ~ "WebZIP"
		|| req.http.User-Agent ~ "WellKnownBot"
		|| req.http.User-Agent ~ "Who.is"
		|| req.http.User-Agent ~ "willnorris"
		|| req.http.User-Agent ~ "Windows Live Writter"			# malicious
		|| req.http.User-Agent == "Wordpress"					# malicious
		|| req.http.User-Agent ~ "Wordpress.com"
		|| req.http.User-Agent ~ "wp.com"
		|| req.http.User-Agent ~ "WWW-Mechanize"
		# X
		|| req.http.User-Agent ~ "XenForo"
		|| req.http.User-Agent ~ "XoviBot"
		|| req.http.User-Agent ~ "xpymep"
		# Y
		|| req.http.User-Agent ~ "yacubot"
		|| req.http.User-Agent ~ "YahooSeeker"
		|| req.http.User-Agent ~ "YaK"							# bad
		|| req.http.User-Agent ~ "Yandex"						# bad
		|| req.http.User-Agent ~ "YisouSpider"
		# Z
		|| req.http.User-Agent ~ "zgrab/"
		|| req.http.User-Agent ~ "zh_CN"						# malicious
		|| req.http.User-Agent ~ "zh-CN"						# malicious
		|| req.http.User-Agent ~ "zh-cn"						# malicious
		|| req.http.User-Agent ~ "ZmEu"
		|| req.http.User-Agent ~ "zoombot"
		|| req.http.User-Agent ~ "ZoomBot"
		|| req.http.User-Agent ~ "ZoominfoBot"
		|| req.http.User-Agent == "Moza"
		## Others
		## CFNetwork, Darwin are always bots, but some are useful. 2345Explorer same thing, but practically always harmful
		## Dalvik is VM of android
		|| req.http.User-Agent ~ "eSobiSubscriber"
		|| req.http.User-Agent ~ "Chrome/[CHROME_VERSION] Mobile Safari/[WEBKIT_VERSION]"  # mostly https://mytuner-radio.com/ lying its UA
#		|| req.http.User-Agent ~ "Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18"
		|| req.http.User-Agent ~ "Opera/9.80 (Windows NT 5.1; U; en) Presto/2.10.289 Version/12.01"
#		|| req.http.User-Agent ~ "Safari/14608.5.12 CFNetwork/978.2 Darwin/18.7.0 (x86_64)" #Maybe Apple, it is checking out mostly only touch-icon.png
		|| req.http.User-Agent ~ "Windows; U; MSIE 9.0; WIndows NT 9.0; de-DE"
		|| req.http.User-Agent ~ "Mac / Chrome 34"
		|| req.http.User-Agent ~ "\x22Mozilla/5.0"
		|| req.http.User-Agent ~ "Mozilla \/4\.0"
#		|| req.http.User-Agent == "Mozilla/5.0(compatible;MSIE9.0;WindowsNT6.1;Trident/5.0)"
#		|| req.http.User-Agent == "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1)"
#		|| req.http.User-Agent == "Mozilla/5.0 (Windows NT 6.1; rv:3.4) Goanna/20180327 PaleMoon/27.8.3"
#		|| req.http.User-Agent == "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36"
		|| req.http.User-Agent == "Mozilla/5.0 (Windows; U; MSIE 9.0; WIndows NT 9.0; de-DE)"
#		|| req.http.User-Agent == "Mozilla/5.8"
#		|| req.http.User-Agent ~ "Mozilla/4.0"
		|| req.http.User-Agent ~ "Windows NT 5.1\; ru\;"
		|| req.http.User-Agent ~ "Windows NT 5.2"
#		|| req.http.User-Agent ~ "(Windows NT 6.0)"
#		|| req.http.User-Agent == "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko"
#		|| req.http.User-Agent == "'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36'"
#		|| req.http.User-Agent ~ "Mozilla/5.1 (Windows NT 6.0; WOW64)"
		|| req.http.User-Agent == "Linux Mozilla"
		|| req.http.User-Agent ~ "x22Mozilla/5.0"
		|| req.http.User-Agent ~ "Mozlila"
		) {
			# First I normalize UAs to be on safe side
			set req.http.User-Agent = "Bad bot";
			set req.http.x-bot = "bad";
			# I'm using this mostly for varnistop
			set req.http.x-user-agent = req.http.User-Agent;
			# My sites are in finnish so I can't ban finnish IPs or IPs using off-shore finnish folk
			# And yes, I know this isn't reliable solution. But hey... don't use fake UAs
			# Everybody else will go to loving hands of Fail2ban
			#if (req.http.X-Country-Code ~ "fi" || 
			if (req.http.x-language ~ "fi") {
				return(synth(403, "Access Denied " + req.http.X-Real-IP));
			} else {
				return(synth(666, "Forbidden Bot " + req.http.X-Real-IP));
			}
		}
		
		# That's all folk.
}    
