#!/bin/bash

# chmod +x purge.sh

# DEFAULT
DEFAULT_DOMAIN="1.example.tld"

# MANUAL
function usage() {
  echo "Use:"
  echo "  $0 <target> <url|xkeytag[,xkeytag2,...]>"
  echo
  echo "Examples:"
  echo "  $0 poochie https://1.example.tld/2025/05/article/"
  echo "  $0 poochie frontpage"
  echo "  $0 poochie sidebar,frontpage,article-123"
  echo
  echo "Targets:"
  echo "  poochie    -> 1.example.tld"
  echo "  kitty    -> 2.example.tld"
  exit 1
}

# DOMAINS
case "$1" in
  poochie) DOMAIN="1.example.tld" ;;
  kitty) DOMAIN="2.example.tld" ;;
  "") usage ;;
  *) echo "Unknown target: $1"; usage ;;
esac

# REMOVE FIRST PARAMETER
shift

# CHECK IF VALUE IS GIVEN
if [ -z "$1" ]; then
  usage
fi

# CHECK IF IT IS URL OR XKEY
if [[ "$1" =~ ^https?:// ]]; then
  echo "Sending PURGE URL: $1"
  curl -s -X PURGE "$1" --http1.1
else
  echo "Sending Xkey PURGE to target: $DOMAIN"
  curl -s -X PURGE "https://${DOMAIN}/" \
    -H "Host: ${DOMAIN}" \
    -H "xkey-purge: $1" \
    --http1.1
fi
