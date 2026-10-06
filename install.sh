#!/usr/bin/env bash
# Installs the Dota 2 fastfetch theme into ~/.config/fastfetch (existing config is backed up).
set -e
src=$(cd "$(dirname "$0")" && pwd)
dst="$HOME/.config/fastfetch"
mkdir -p "$dst/ascii"
if [ -f "$dst/config.jsonc" ]; then
  cp "$dst/config.jsonc" "$dst/config.jsonc.bak.$(date +%Y%m%d%H%M%S)"
  echo "Old config backed up in $dst"
fi
cp "$src/config.jsonc" "$dst/config.jsonc"
cp "$src/dota.sh" "$dst/dota.sh"
cp "$src/ascii/dota2.txt" "$src/ascii/dota2-gradient.txt" "$dst/ascii/"
chmod +x "$dst/dota.sh"
echo "Done. Run: fastfetch"
