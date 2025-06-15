#!/usr/bin/env python3
import requests
import subprocess
import tempfile
import datetime
import sys
import time

MATOMO_API_URL = "https://stats.eksis.eu/index.php"
TOKEN = "71e06dc07870c9e6a22f8a4323d7970f"  # Vaihda oikea token

# Nickname - Matomo ID - url
SITES = {
    "katiska": {"id": 1, "domain": "www.katiska.eu"},
    "poochie": {"id": 15, "domain": "www.poochierevival.info"},
    "eksis": {"id": 2, "domain": "www.eksis.one"},
    "selko": {"id": 5, "domain": "selko.katiska.eu"},
    "dev": {"id": 11, "domain": "dev.eksis.one"},
    "jagster": {"id": 17, "domain": "jagster.eksis.one"},
}

HEADERS = {
    "User-Agent": "CacheWarmer/1.0"
}


def matomo_api_call(params):
    try:
        response = requests.get(MATOMO_API_URL, params=params, headers=HEADERS, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"[Virhe] Matomo API-pyyntö epäonnistui: {e}")
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

    print("⏳ Haetaan Matomolta pääsivuston URLit...")
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

        # 🖥️ Tulosta mitä tehdään
        print(f"📛 BANNING: {path}")

        ban_expr = f'req.url ~ "^{path}"'
        try:
            subprocess.run([
                "varnishadm", "-S", "/etc/varnish/secret",
                "-T", "localhost:6082", "ban", ban_expr
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"[Virhe] {full_url}: Varnish ban epäonnistui: {e}")
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
            print(f"[Virhe] {full_url}: Fetch epäonnistui: {e}")

    return warmed_urls


def main():
    if len(sys.argv) != 2:
        print("Käyttö: ./cache-warmer.py <sivuston_nimi>")
        sys.exit(1)

    site_name = sys.argv[1]
    if site_name not in SITES:
        print(f"[Virhe] Tuntematon sivusto: {site_name}")
        sys.exit(1)

    today = datetime.date.today()
    start = today - datetime.timedelta(days=30) # time frame
    end = today

    site = SITES[site_name]
    domain = site["domain"]

    urls = get_top_urls(site["id"], start.isoformat(), end.isoformat())

    if not urls:
        print("⚠️  Yhtään URLia ei löytynyt.")
        sys.exit(1)

    with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.txt') as tmp_file:
        for path in urls:
            if not path.startswith("/"):
                path = "/" + path
            full_url = f"https://{domain}{path}"
            tmp_file.write(full_url + "\n")
        tmp_filename = tmp_file.name

    print(f"📄 URL-lista tallennettu: {tmp_filename}")
    print(f"🔥 Lämmitetään cache {len(urls)} URLille...\n")

    warmed = ban_and_warm(domain, urls)

    print(f"\n✅ Valmis. {len(warmed)} URLia lämmitetty backendiltä.")


if __name__ == "__main__":
    main()
