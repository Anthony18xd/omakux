#!/usr/bin/env bash
# omakux — historial del portapapeles (cliphist + wofi)
set -euo pipefail

if ! command -v cliphist >/dev/null 2>&1; then
  notify-send -u low "Portapapeles" "cliphist no instalado"
  exit 1
fi

sel="$(cliphist list | wofi -dmenu -p "portapapeles" -i --insensitive)" || exit 0
[ -n "$sel" ] || exit 0
printf '%s' "$sel" | cliphist decode | wl-copy
notify-send -u low -h string:x-canonical-private-synchronous:clipboard "Portapapeles" "copiado"
