#!/usr/bin/env bash
set -euo pipefail

VMOD_PREFIX="/usr"
SRC_DIR="/usr/local/src/varnish-modules"
VMOD_TAG="0.26.0"   # Varnish 7.7: katso Releases-sivulta oikea tagi

echo "[*] Varnishd: $(varnishd -V 2>&1 | head -n1)"
echo "[*] Varnish API: $(pkg-config --modversion varnishapi)"

sudo apt-get update -qq
sudo apt-get install -y \
  git build-essential automake libtool autotools-dev pkg-config \
  python3-docutils python3-sphinx varnish-dev

if [[ ! -d "$SRC_DIR" ]]; then
  sudo git clone https://github.com/varnish/varnish-modules.git "$SRC_DIR"
fi

cd "$SRC_DIR"
sudo git fetch --all -p --tags
sudo git checkout "$VMOD_TAG"

sudo ./bootstrap
sudo ./configure --prefix="$VMOD_PREFIX"
make -j"$(nproc)"
make check || true
sudo make rst-docs
sudo make install

echo "[*] Installed xkey at:"
sudo find /usr -path "*/varnish/vmods/libvmod_xkey.so" -ls || true
