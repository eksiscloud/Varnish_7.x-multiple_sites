#!/usr/bin/env python3

# Usage: ./cache-warmer.py <nickname> [COUNTRY CODE]

import requests
import subprocess
import tempfile
import datetime
import sys
import time
from bs4 import BeautifulSoup

MATOMO_API_URL = "YOUR-MATOMO"
TOKEN = "API-KEY"

# Add your sites
SITES = {
    "katiska": {"id": 1, "domain": "www.katiska.eu"},
    "poochie": {"id": 15, "domain": "www.poochierevival.info"},
    "eksis": {"id": 2, "domain": "www.eksis.one"},
    "jagster": {"id": 17, "domain": "jagster.eksis.one"},
    "dev": {"id": 11, "domain": "dev.eksis.one"},
}

# Change if needed
HEADERS = {
    "User-Agent": "CacheWarmer/1.1",
    "Accept": "*/*",
    "X-Bypass": "false"
}

def matomo_api_call(params, max_retries=3, timeout=20):
    for attempt in range(max_retries):
        try:
            response = requests.get(MATOMO_API_URL, params=params, headers=HEADERS, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"[Error] Matomo API-request failed (attwmpt {attempt+1}/{max_retries}): {e}")
            time.sleep(2)
    return []

def get_top_urls(site_id, start_date, end_date, country=None):
    params = {
        "module": "API",
        "method": "Actions.getPageUrls",
        "idSite": site_id,
        "period": "range",
        "date": f"{start_date},{end_date}",
        "format": "JSON",
        "filter_limit": "400",
        "token_auth": TOKEN,
    }

    if country:
        params["segment"] = f"countryCode=={country}"

    print("⏳ Getting main URLs from Matomo...")
    data = matomo_api_call(params)
    urls = []

    for entry in data:
        label = entry.get("label")
        if label:
            urls.append(label)

        sub_id = entry.get("idsubdatatable")
        if sub_id:
            sub_params = params.copy()
            sub_params["idSubtable"] = sub_id
            sub_data = matomo_api_call(sub_params)
            for sub_entry in sub_data:
                sub_label = sub_entry.get("label")
                if sub_label:
                    urls.append(f"{label.rstrip('/')}/{sub_label.lstrip('/')}")

            time.sleep(0.5)

    return urls

def ban_and_warm(domain, urls):
    warmed_urls = []

    for idx, path in enumerate(urls):
        if not path.startswith("/"):
            path = "/" + path.rstrip("/") + "/"
        full_url = f"https://{domain}/{path.lstrip('/')}"

	# First happens hard PURGE to be sure we have fresk copy (BAN would fill up ban.list)
        print(f"📛 BANNING: {path}")
        headers = {
            "xkey-purge": f"url-{path}",
            "X-Bypass": "true",
            "User-Agent": "CacheWarmer/1.1"
        }
        try:
            response = requests.request("PURGE", full_url, headers=headers, timeout=10)
            print(f"✅ PURGED: {path}" if response.status_code == 200 else f"📛 PURGE FAILED: {path} → {response.status_code} {response.reason}")
        except requests.exceptions.RequestException as e:
            print(f"[Error] PURGE-reguest failed: {e}")
            continue

        # Getting a fresh one from backend
        print(f"🚀 FETCHING: {full_url}")
        headers_fetch = {
            "User-Agent": "CacheWarmer/1.1",
            "X-Bypass": "true",
        }
        try:
            get_response = requests.get(full_url, headers=headers_fetch, timeout=10)
            print(f"← GET {get_response.status_code}: {get_response.reason}")
            print(f"← X-Cache: {get_response.headers.get('x-cache', 'ei headeria')}")
            warmed_urls.append(full_url)

            # assets from only the first 3 hits, those are same anyway
            if idx < 3:
                soup = BeautifulSoup(get_response.text, 'html.parser')
                asset_urls = set()

                for tag in soup.find_all(["link", "script", "img"]):
                    url = tag.get("href") or tag.get("src")
                    if url and (url.endswith((".css", ".js", ".woff", ".woff2", ".ttf", ".otf", ".eot", ".svg", ".png", ".jpg", ".jpeg", ".gif", ".webp"))):
                        if url.startswith("/"):
                            asset_urls.add(f"https://{domain}{url}")
                        elif url.startswith("http"):
                            asset_urls.add(url)

                for asset in asset_urls:
                    try:
                        response = requests.get(asset, headers=headers_fetch, timeout=10)
                        print(f"    ↳ Asset {asset} → {response.status_code}")
                    except Exception as e:
                        print(f"[Error] Getting an asset failed: {e}")

        except Exception as e:
            print(f"[Virhe] GET-request failed: {e}")

    return warmed_urls

def main():
    if len(sys.argv) < 2:
        print("Usage: ./cache-warmer.py <nickname> [COUNTRY CODE]")
        sys.exit(1)

    site_name = sys.argv[1]
    if site_name not in SITES:
        print(f"[Error] Unknown site: {site_name}")
        sys.exit(1)

    country = sys.argv[2] if len(sys.argv) > 2 else None

    today = datetime.date.today()
    start = today - datetime.timedelta(days=45)
    end = today

    site = SITES[site_name]
    domain = site["domain"]

    urls = get_top_urls(site["id"], start.isoformat(), end.isoformat(), country)

    if not urls:
        print("⚠️   No URL couldn't find")
        sys.exit(1)

    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.txt') as tmp_file:
        for path in urls:
            if not path.startswith("/"):
                path = path.rstrip("/") + "/"
            full_url = f"https://{domain}/{path.lstrip('/')}"
            tmp_file.write(full_url + "\n")
        tmp_filename = tmp_file.name

    print(f"📄 URL-list saved: {tmp_filename}")
    print(f"🔥 Warming up cache using  {len(urls)} URLs...\n")

    warmed = ban_and_warm(domain, urls)
    print(f"\n✅ Ready. {len(warmed)} URLs from backend is used for cache warming.")

if __name__ == "__main__":
    main()
