#!/usr/bin/env bash
# omakux — grabación de pantalla (wf-recorder)
set -euo pipefail

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imágenes")/Grabaciones"
mkdir -p "$dir"
pidfile="/tmp/omakux-rec.pid"

if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  kill "$(cat "$pidfile")" 2>/dev/null || true
  rm -f "$pidfile"
  notify-send -u low "Grabación" "detenida"
  exit 0
fi

if ! command -v wf-recorder >/dev/null 2>&1; then
  notify-send -u critical "Grabación" "wf-recorder no instalado"
  exit 1
fi

file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
geom="$(slurp 2>/dev/null)" || exit 0
[ -n "$geom" ] || exit 0

wf-recorder -g "$geom" -f "$file" >/dev/null 2>&1 &
echo $! >"$pidfile"
notify-send -u low "Grabación" "iniciada — Super+Shift+R para detener"
