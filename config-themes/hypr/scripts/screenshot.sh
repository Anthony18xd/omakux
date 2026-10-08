#!/usr/bin/env bash
# omakux — capturas de pantalla: omakux-capture [area|full|screen]
set -euo pipefail

mode="${1:-area}"
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imágenes")/Capturas"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
  area | area-linux)
    geom="$(slurp 2>/dev/null)" || exit 0
    [ -n "$geom" ] || exit 0
    grim -g "$geom" "$file"
    ;;
  screen)
    grim "$file"
    ;;
  full)
    grim "$file"
    ;;
  window)
    # ventana enfocada vía hyprctl
    geom="$(hyprctl -j activewindow 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || true)"
    if [ -n "${geom:-}" ] && [ "$geom" != "null" ]; then
      grim -g "$geom" "$file"
    else
      grim "$file"
    fi
    ;;
  *)
    echo "uso: screenshot.sh [area|full|screen|window]" >&2
    exit 1
    ;;
esac

wl-copy <"$file" 2>/dev/null || true
notify-send -u low -h string:x-canonical-private-synchronous:screenshot \
  -i "$file" "Captura guardada" "$file (copiada al portapapeles)"
