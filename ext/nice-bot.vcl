sub cute_bot_allowance {

	## Useful bots, spiders etc.
	# I'm using x-bot somekind of ACL
	
	if (
		# Google
		   req.http.User-Agent ~ "APIs-Google"
		|| req.http.User-Agent ~ "Mediapartners-Google"
		|| req.http.User-Agent ~ "AdsBot-Google"
		|| req.http.User-Agent ~ "Googlebot"
		|| req.http.User-Agent ~ "FeedFetcher-Google"
		|| req.http.User-Agent ~ "Google-Read-Aloud"
		|| req.http.User-Agent ~ "DuplexWeb-Google"
		|| req.http.User-Agent ~ "Google Favicon"
		|| req.http.User-Agent ~ "GoogleImageProxy" #anonymizes Gmail openings and is a human
		|| req.http.User-Agent ~ "Googlebot-Video"
		|| req.http.User-Agent ~ "AppEngine-Google" #snapchat
		|| req.http.User-Agent == "Chrome Privacy Preserving Prefetch Proxy"
		|| req.http.User-Agent == "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246 Mozilla/5.0" # the actual gmail bot
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "Google";
			set req.http.x-user-agent = req.http.User-Agent; 
		}
		
	if (
		# Microsoft
		req.http.User-Agent ~ "Bingbot"
		|| req.http.User-Agent ~ "bingbot"
		|| req.http.User-Agent ~ "msnbot"
		#|| req.http.User-Agent ~ "BingPreview"	# done elsewhere
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "Bing"; 
			set req.http.x-user-agent = req.http.User-Agent;
		}
		
	if (
		# DuckDuckGo
		req.http.User-Agent ~ "DuckDuckBot"
		|| req.http.User-Agent ~ "DuckDuckGo-Favicons-Bot"
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "DuckDuckGo"; 
			set req.http.x-user-agent = req.http.User-Agent;
		}
		
	if (
                # DuckDuckGo
                req.http.User-Agent ~ "Mastodon"
                ) {
                        set req.http.x-bot = "nice";
                        set req.http.User-Agent = "Mastodon";
                        set req.http.x-user-agent = req.http.User-Agent;
                }


	if (
		# Apple
		req.http.User-Agent ~ "Applebot"
		|| req.http.User-Agent ~ "AppleCoreMedia"
		|| req.http.User-Agent ~ "atc/"				# WatchOS, Podcasts
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "Apple"; 
			set req.http.x-user-agent = req.http.User-Agent;
		}
		
	if (
		req.http.User-Agent == "iTMS"					# iTunes
		|| req.http.User-Agent ~ "Jakarta Commons-HttpClient"		# always together with iTMS
		|| req.http.User-Agent ~ "(Podcastit|Podcaster|Podcasts)"	# Apple Podcast-app
		|| req.http.User-Agent ~ "iTunes"				# Older way to get podcasts, will disappers I reckon
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "iTunes"; 
			set req.http.x-user-agent = req.http.User-Agent;
		}
		
	if (
		# Facebook
		req.http.User-Agent ~ "externalhit_uatext"
		|| req.http.User-Agent ~ "facebookexternalhit"
		|| req.http.User-Agent ~ "cortex"
		|| req.http.User-Agent ~ "adreview"
		|| req.http.User-Agent ~ "meta-externalagent"
		) { 
			set req.http.x-bot = "nice"; 
			set req.http.User-Agent = "Facebook"; 
			set req.http.x-user-agent = req.http.User-Agent;
		}
		
	# podcasts
	# Allowed:
	# Air
	# Amazon Music Podcast
	# AntennaPod
	# Breaker
	# CastBox
	# Overcast
	# Spotify
	# StitcherBot

	if (req.http.User-Agent ~ "Airr/") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Airr"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}	# https://www.airr.io/

	if (req.http.User-Agent == "Amazon Music Podcast") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Amazon Podcast"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "AntennaPod") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "AntennaPod"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}	# https://github.com/AntennaPod/AntennaPod

	if (req.http.User-Agent ~ "Breaker") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Breaker"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "CastBox") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "CastBox"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "OAI-SearchBot") {
		set req.http.x-bot = "nice";
		set req.http.User-Agent = "OpenAI Search";
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Overcast") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Overcast"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Spotify") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Spotify"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "StitcherBot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Stitcher"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}
	
	# Others
	if (req.http.User-Agent ~ "(ia_archiver|AlexaMediaPlayer)") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Alexa"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Blekkobot") {
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Blekko"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Discourse") {
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Discourse"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent == "Amazon Simple Notification Service Agent") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "AWS"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "^MeWeBot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "MeWe"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "TurnitinBot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "TurnitinBot"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "archive.org") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Internet Archiver"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Feedly") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Feedly"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "MetaFeedly") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "MetaFeedly"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Bloglovin") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Bloglovin"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Moodlebot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Moodle"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "TelegramBot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Telegram"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}
	
	if (req.http.User-Agent ~ "^Twitterbot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Twitter"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Pinterestbot") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Pinterest"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "WhatsApp") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "WhatsApp"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Snapchat") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Snapchat"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	if (req.http.User-Agent ~ "Newsify") { 
		set req.http.x-bot = "nice"; 
		set req.http.User-Agent = "Newsify"; 
		set req.http.x-user-agent = req.http.User-Agent;
	}

	## For logging
	if (req.http.x-bot == "nice") {
		std.log("BOT_DETECTED IP=" + req.http.X-Real-IP + " " + req.http.X-Country-Code + " User-Agent:" + req.http.User-Agent);
	}
	
	# That's it, folk
}
