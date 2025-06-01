sub asn_name {

	## Not ASN but is here anyway: stopping some sites using ACL and reverse DNS
	if (std.ip(req.http.X-Real-IP, "0.0.0.0") ~ forbidden) {
                return (synth(403, "Access Denied " + req.http.X-Real-IP));
        }

	## If you have just another website for real users maybe It is wise move to ban every single one VPS service
	## you don't need for APIs etc.
	# Heads up: ASN can and quite often will stop more than just one company
	# Just coming from some ASN doesn't be reason to hard banning,
	# but everyone here is knocking too often so I'll keep doors closed

	# ASN can be empty sometimes. i stop those request, because it is suspicious
	#if (!req.http.X-ASN || req.http.X-ASN == "unknown") {
	#	std.log("Missing ASN info for: " + req.http.X-Real-IP);
	#	return(synth(400, "Missing ASN"));
	#}

	# Actual filtering
	if (
		   req.http.x-asn ~ "alibaba"				# Alibaba (US) Technology Co., Ltd., US,CN
		|| req.http.x-asn ~ "avast-as-cd"					# Privax LTD, GB etc.
		|| req.http.x-asn ~ "bladeservers"			# LeaseVPS, NL, AU
		|| req.http.x-asn == "cogent-174"			# BlackHOST Ltd., NL
		|| req.http.x-asn ~ "contabo"				# Contabo Inc., US
		|| req.http.x-asn ~ "corporacion dana"			# Computer Company, US but is HN
		|| req.http.x-asn ~ "cypresstel"			# Cypress Telecom Limited, HK
		|| req.http.x-asn ~ "digital energy technologies"	# BG
		|| req.http.x-asn ~ "dreamscape"			# Vodien Internet Solutions Pte Ltd, HK, SG, AU
		|| req.http.x-asn ~ "go-daddy-com-llc"			# GoDaddy.com US (GoDaddy isn't serving any useful services too often)
		|| req.http.x-asn ~ "hvc-as"				# NOC4Hosts Inc., US
		|| req.http.x-asn ~ "idcloudhost"			# PT. SIBER SEKURINDO TEKNOLOGI, PT Cloud Hosting Indonesia, ID
		|| req.http.x-asn ~ "int-network"			# IP Volume inc, SC
		|| req.http.x-asn ~ "internet-it"			# INTERNET IT COMPANY INC, SC
		|| req.http.x-asn ~ "logineltdas"			# Karolio IT paslaugos, LT, US, GB
		|| req.http.x-asn ~ "networksdelmanana"			# Yaroslav Kharitonova, UY via HN from RU
		|| req.http.x-asn == "njix"				# laceibaserver.com, DE, US
		|| req.http.x-asn ~ "online sas"			# IP Pool for Iliad-Entreprises Business Hosting Customers, FR
		|| req.http.x-asn ~ "planeetta-as"			# Planeetta Internet Oy, FI
		|| req.http.x-asn ~ "railnet"				# Railnet LLM, US
		|| req.http.x-asn ~ "scalaxy"				# xWEBltd, actually RU using NL and identifying as GB
		|| req.http.x-asn ~ "server-mania"			# B2 Net Solutions Inc., CA
		|| req.http.x-asn ~ "suddenlink-communications"		# Suddenlink Communications, US
		|| req.http.x-asn ~ "reliablesite"			# Dedires llc, GB from PSE
		|| req.http.x-asn ~ "tefincomhost"			# Packethub S.A., NordVPN, FI, PA
		|| req.http.x-asn ~ "whg-network"			# Web Hosted Group Ltd, GB
		|| req.http.x-asn == "wii"				# Wholesale Internet, Inc US
		) {
			if (req.url !~ "/wp-login") {
				std.log("stopped ASN: " + req.http.x-asn);
				return(synth(666, "Forbidden organization: " + std.toupper(req.http.x-asn)));
			} else {
				std.log("banned ASN: " + req.http.x-asn);
				return(synth(423, "Severe security issues: " + std.toupper(req.http.x-asn)));
			}
		}
		
	## These are really bad ones and will be banned by Fail2ban
	# It is just smart move to ban theirs IP-space totally in Fail2ban
	if (
		   req.http.x-asn ~ "adsafe-"				# Integral Ad Science, Inc., US
		|| req.http.x-asn ~ "as_delis"				# Serverion BV, NL
		|| req.http.x-asn ~ "blazingseo"			# DE but is from IL
		|| req.http.x-asn ~ "chinanet-backbone"			# big part of China
		|| req.http.x-asn ~ "chinatelecom"			# a lot and couple more, CN
		|| req.http.x-asn ~ "colocrossing"			# ColoCrossing, US
		|| req.http.x-asn ~ "cyberverse"			# Evocative, Inc./ChunkHost, US
		|| req.http.x-asn ~ "deltahost"				# DeltaHost, NL but actually UA
		|| req.http.x-asn ~ "dreamhost"				# New Dream Network, LLC, US
		|| req.http.x-asn ~ "emerald-onion"			# Emerald Onion/Tor exit, US
		|| req.http.x-asn ~ "iomart"				# IOMART HOSTING LIMITED. GB
		|| req.http.x-asn ~ "ionos"				# 1&1 IONOS Inc., US, SE, DE
		|| req.http.x-asn ~ "leaseweb"				# LeaseWeb Netherlands B.V., NL
		|| req.http.x-asn ~ "m247"				# QuickPacket, LLC, US, m247.com, GB, ES, RO
		|| req.http.x-asn ~ "nocix"				# Nocix, LLC, US
		|| req.http.x-asn ~ "ovh"				# OVH SAS, FR
		|| req.http.x-asn ~ "peenq"				# PEENQ, NL
		|| req.http.x-asn ~ "ponynet"				# FranTech Solutions, US
		|| req.http.x-asn ~ "powerline-as"			# Ngok Fung trading, HK
		|| req.http.x-asn ~ "selectel"				# Starcrecium Limited, CY is actually RU
		|| req.http.x-asn ~ "serverion"				# Serverion BV, NL
		|| req.http.x-asn ~ "squitter-networks"			# ABC Consultancy etc, CINTY EU WEB SOLUTIONS, NL
		|| req.http.x-asn ~ "velianet"				# velia.net Internetdienste GmbH, FR is actually RU
		|| req.http.x-asn ~ "wellnet"				# xWEBltd, NL is really RU
		) {
			std.log("banned ASN: " + req.http.x-asn);
			return(synth(423, "Severe security issues: " + std.toupper(req.http.x-asn)));
		}

	## If you reach this point, you are propably a good guy, so let's remove ASN. It isn't needed anymore.
	unset req.http.X-ASN;

# The end of the sub
}
