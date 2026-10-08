#!/usr/bin/env bash
# omakux — menú de energía (wofi)
set -euo pipefail

choice="$(printf '%s\n' "🔒 Bloquear" "↩ Cerrar sesión" "↻ Reiniciar" "⏻ Apagar" |
  wofi -dmenu -p "energía" --insensitive)" || exit 0

case "$choice" in
  *Bloquear*) hyprlock ;;
  *sesión*) hyprctl dispatch exit ;;
  *Reiniciar*) systemctl reboot ;;
  *Apagar*) systemctl poweroff ;;
esac
