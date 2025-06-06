#!/bin/bash

# Varmistetaan että ollaan main-haarassa
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  echo "⚠️ Et ole main-haarassa (nyt: $current_branch)."
  read -p "Haluatko jatkaa silti? (y/n) " continueanyway
  if [[ "$continueanyway" != "y" ]]; then
    echo "⛔ Keskeytetään."
    exit 1
  fi
fi

# Näytetään nykyinen HEAD commit
echo "🔍 Nykyinen HEAD:"
git log -1 --oneline

# Kysytään tagin nimi ja kuvaus
echo ""
read -p "Anna tagin nimi (esim. pre-asn-refactor-20250606): " tagname
read -p "Anna lyhyt kuvaus: " tagdesc

# Luodaan annotoitu tagi
git tag -a "$tagname" -m "$tagdesc"
echo "✅ Tagi '$tagname' luotu."

# Kysytään lähetetäänkö GitHubiin
read -p "Haluatko lähettää tagin GitHubiin? (y/n) " pushit
if [[ "$pushit" == "y" ]]; then
  git push origin "$tagname"
  echo "📡 Tagi lähetetty GitHubiin."
else
  echo "🚫 Tagi jäi paikalliseksi."
fi
