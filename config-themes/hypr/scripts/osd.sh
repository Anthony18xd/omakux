#!/usr/bin/env bash
# omakux — OSD de volumen/brillo vía notificaciones (dunst)
set -u

kind="${1:-volume}"
case "$kind" in
  volume)
    vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
    pct="$(echo "$vol" | awk '{printf "%d", $2 * 100}')"
    muted="$(echo "$vol" | grep -q MUTED && echo 1 || echo 0)"
    if [ "$muted" = "1" ]; then
      msg="silenciado"
      pct=0
    else
      msg="${pct}%"
    fi
    icon="audio-volume-high"
    [ "$pct" -lt 40 ] && icon="audio-volume-low"
    [ "$pct" -ge 40 ] && [ "$pct" -lt 80 ] && icon="audio-volume-medium"
    notify-send -u low -h "int:value:$pct" \
      -h "string:x-canonical-private-synchronous:omakux-osd" \
      -i "$icon" "Volumen" "$msg"
    ;;
  brightness)
    pct="$(brightnessctl -m | awk -F, '{print $4}' | tr -d %)"
    notify-send -u low -h "int:value:$pct" \
      -h "string:x-canonical-private-synchronous:omakux-osd" \
      -i "display-brightness" "Brillo" "${pct}%"
    ;;
esac
