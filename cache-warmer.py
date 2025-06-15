#!/usr/bin/env python3
import requests
import subprocess
import tempfile
import datetime
import sys
import time

MATOMO_API_URL = "https://matomo/index.php" # change this
TOKEN = "matomo-api-token"  # change this

# Nickname - Matomo ID - url
SITES = {
    "example": {"id": 1, "domain": "www.example.com"},
    "another": {"id": 15, "domain": "www.example.tld"},
}

HEADERS = {
    "User-Agent": "CacheWarmer/1.0" # what ever you like
}


def matomo_api_call(params):
    try:
        response = requests.get(MATOMO_API_URL, params=params, headers=HEADERS, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"[Error] Matomo API-request failed: {e}")
        return []


def get_top_urls(site_id, start_date, end_date):
    params = {
        "module": "API",
        "method": "Actions.getPageUrls",
        "idSite": site_id,
        "period": "range",
        "date": f"{start_date},{end_date}",
        "format": "JSON",
        "filter_limit": "200", # top-200
        "token_auth": TOKEN,
    }

    print("Get main urls from Matomo...")
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

    for path in urls:
        if not path.startswith("/"):
            path = "/" + path
        full_url = f"https://{domain}{path}"

        # Printing what is happening
        print(f"📛 BANNING: {path}")

        ban_expr = f'req.url ~ "^{path}"'
        try:
            subprocess.run([
                "varnishadm", "-S", "/etc/varnish/secret",
                "-T", "localhost:6082", "ban", ban_expr
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"[Error] {full_url}: Varnish BAN failed: {e}")
            continue

        print(f"🔥 FETCHING: {full_url}\n")
        try:
            subprocess.run([
                "curl", "-s",
                "-H", "X-Bypass-Cache: 1",
                "-H", "User-Agent:CacheWarmer",
                full_url
            ], stdout=subprocess.DEVNULL, check=True)
            warmed_urls.append(full_url)
        except subprocess.CalledProcessError as e:
            print(f"[Error] {full_url}: Fetch failed: {e}")

    return warmed_urls


def main():
    if len(sys.argv) != 2:
        print("Usage: ./cache-warmer.py <nickname>")
        sys.exit(1)

    site_name = sys.argv[1]
    if site_name not in SITES:
        print(f"[Error] Unknown site: {site_name}")
        sys.exit(1)

    today = datetime.date.today()
    start = today - datetime.timedelta(days=30) # time frame
    end = today

    site = SITES[site_name]
    domain = site["domain"]

    urls = get_top_urls(site["id"], start.isoformat(), end.isoformat())

    if not urls:
        print("Couldn't find any site")
        sys.exit(1)

    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.txt') as tmp_file:
        for path in urls:
            if not path.startswith("/"):
                path = "/" + path
            full_url = f"https://{domain}{path}"
            tmp_file.write(full_url + "\n")
        tmp_filename = tmp_file.name

    print(f"URL list saved: {tmp_filename}")
    print(f"🔥 Warming up cache for {len(urls)} URLs...\n")

    warmed = ban_and_warm(domain, urls)

    print(f"\n✅ Ready. {len(warmed)} URLs from the backend are warmed up.")


if __name__ == "__main__":
    main()
