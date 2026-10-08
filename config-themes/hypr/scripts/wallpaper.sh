#!/usr/bin/env bash
# omakux — aplica el fondo de pantalla activo (GNOME y Hyprland comparten archivo)
set -u

STATE="${OMAKUX_STATE:-$HOME/.local/state/omakux}"
wp="$STATE/wallpapers/active.png"
[ -f "$wp" ] || wp="$STATE/wallpapers/active.svg"

if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || [ "${HYPRLAND_INSTANCE_SIGNATURE:-}" != "" ]; then
  pkill -x swaybg 2>/dev/null || true
  if [ -f "$wp" ]; then
    swaybg -i "$wp" -m fill >/dev/null 2>&1 &
  fi
fi
