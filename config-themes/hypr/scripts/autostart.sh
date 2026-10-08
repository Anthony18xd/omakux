#!/usr/bin/env bash
# omakux — autostart de la sesión Hyprland
set -u

# polkit agent
for p in /usr/libexec/hyprpolkitagent/hyprpolkitagent \
  /usr/lib/hyprpolkitagent/hyprpolkitagent \
  /usr/libexec/polkit-kde-authentication-agent-1; do
  if [ -x "$p" ]; then
    pgrep -f "$(basename "$p")" >/dev/null 2>&1 || "$p" &
    break
  fi
done

# applets
pgrep -x nm-applet >/dev/null 2>&1 || nm-applet --indicator >/dev/null 2>&1 &
pgrep -x blueman-applet >/dev/null 2>&1 || blueman-applet >/dev/null 2>&1 &

# cursor
hyprctl setcursor Yaru 24 2>/dev/null || true

# portal filechooser en la sesión GNOME cuando se abre desde Hyprland
# (los portales se configuran vía Hyprland-portals.conf)

# clipboard: portapapeles histórico
command -v wl-paste >/dev/null 2>&1 || true
