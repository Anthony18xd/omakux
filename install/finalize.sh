#!/usr/bin/env bash
# omakux:summary Final touches: symlink, caches and summary
# omakux:group install
# sourced by install.sh — do not execute directly

if [ "$OMAKUX_DRY" != "1" ]; then
  ensure_symlink "$OMAKUX_PATH/bin/omakux" /usr/local/bin/omakux

  has update-desktop-database && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  has fc-cache && fc-cache -f >/dev/null 2>&1 || true
  has gtk-update-icon-cache && gtk-update-icon-cache -f -t /usr/share/icons/Yaru >/dev/null 2>&1 || true

  # gnome: refrescar shell para extensiones/keybindings si estamos en sesión
  if [ "${XDG_CURRENT_DESKTOP:-}" = "ubuntu:GNOME" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "GNOME" ]; then
    dbus-send --type=method_call --dest=org.gnome.Shell \
      /org/gnome/Shell org.gnome.Shell.Eval string:'true' >/dev/null 2>&1 || true
  fi
fi

echo
echo "┌──────────────────────────────────────────────────────┐"
echo "│  omakux v$(cat "$OMAKUX_PATH/version") — instalación completa             │"
echo "└──────────────────────────────────────────────────────┘"
echo
echo "  · Sesiones: cierra sesión → en GDM elige GNOME o Hyprland"
echo "  · CLI:      omakux            (lista) · omakux help <comando> (ficha)"
echo "  · Menú:     Super+Espacio (Hyprland) · 'omakux menu' (GNOME)"
echo "  · Temas:    omakux theme list (tokyonight · catppuccin-mocha · gruvbox-dark)"
echo "  · Snapshots: timeshift diario 09:00 → omakux snapshot list"
echo "  · Update:   omakux update"
echo "  · Doctor:   omakux doctor"
echo
echo "  Si algo falla: omakux doctor · log en $OMAKUX_LOG"
