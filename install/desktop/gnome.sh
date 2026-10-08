#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ "return || exit": fallback para cuando el script se ejecuta en vez de sourcearse
# omakux:summary Configure GNOME: tweaks, fonts, dock, keybindings, defaults
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo
apt_install_list "$OMAKUX_PATH/install/packages/desktop.apt"

if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY: gsettings/dconf de GNOME"
  return 0 2>/dev/null || exit 0
fi

gs() { # gs <schema> <key> <value>
  local schema="$1" key="$2" value="$3"
  if gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    gsettings set "$schema" "$key" "$value" 2>/dev/null || warn "gsettings $schema $key"
  else
    warn "esquema/key no disponible: $schema $key"
  fi
}

log "ajustes de interfaz"

# apariencia
gs org.gnome.desktop.interface color-scheme "'prefer-dark'"
gs org.gnome.desktop.interface accent-color "'blue'"
gs org.gnome.desktop.interface gtk-theme "'Adwaita-dark'"
gs org.gnome.desktop.interface icon-theme "'Yaru'"
gs org.gnome.desktop.interface cursor-theme "'Yaru'"
gs org.gnome.desktop.interface enable-animations "true"

# tipografía (JetBrains Mono en todo lo monoespaciado)
gs org.gnome.desktop.interface monospace-font-name "'JetBrains Mono 11'"
gs org.gnome.desktop.interface document-font-name "'Sans 11'"
gs org.gnome.desktop.interface font-name "'Cantarell 11'"
gs org.gnome.desktop.interface font-antialiasing "'rgba'"
gs org.gnome.desktop.interface font-hinting "'full'"

# reloj
gs org.gnome.desktop.interface clock-show-date "true"
gs org.gnome.desktop.interface clock-show-weekday "true"
gs org.gnome.desktop.interface clock-format "'24h'"

# ventanas y espacios de trabajo
gs org.gnome.desktop.wm.preferences resize-with-right-button "true"
gs org.gnome.mutter dynamic-workspaces "true"
gs org.gnome.mutter attach-modal-dialogs "true"
gs org.gnome.desktop.peripherals.touchpad tap-to-click "true"
gs org.gnome.desktop.peripherals.touchpad natural-scroll "true"

# pantalla: noche, ahorro, bloqueo
gs org.gnome.settings-daemon.plugins.color night-light-enabled "true"
gs org.gnome.desktop.session idle-delay "uint32 300"
gs org.gnome.desktop.screensaver lock-enabled "true"
gs org.gnome.desktop.screensaver lock-delay "uint32 30"
gs org.gnome.desktop.screensaver picture-uri "'file:///usr/share/backgrounds/ubuntu-wallpaper-c.png'" 2>/dev/null || true

# Ubuntu Dock (dash-to-dock)
log "dock de Ubuntu"
gs org.gnome.shell.extensions.dash-to-dock dock-position "'LEFT'"
gs org.gnome.shell.extensions.dash-to-dock extend-height "false"
gs org.gnome.shell.extensions.dash-to-dock autohide "false"
gs org.gnome.shell.extensions.dash-to-dock show-show-apps-button "true"
gs org.gnome.shell.extensions.dash-to-dock show-mounts "false"
gs org.gnome.shell.extensions.dash-to-dock click-action "'previews'"
gs org.gnome.shell.extensions.dash-to-dock show-trash "true"
gs org.gnome.shell.extensions.dash-to-dock isolate-workspaces "false"
gs org.gnome.shell.extensions.dash-to-dock apply-custom-theme "false"

# extensiones activas: preserva las existentes y asegura las de Ubuntu
enabled="$(gsettings get org.gnome.shell enabled-extensions)"
for ext in ubuntu-dock@ubuntu.com ubuntu-appindicators@ubuntu.com tiling-assistant@ubuntu.com; do
  case "$enabled" in *"$ext"*) continue ;; esac
  [ -d "/usr/share/gnome-shell/extensions/$ext" ] || continue
  if [ "$enabled" = "[]" ]; then
    enabled="['$ext']"
  else
    enabled="${enabled%\]},'$ext']"
  fi
done
gs org.gnome.shell enabled-extensions "$enabled"

# --- terminal por defecto: alacritty ---
log "terminal por defecto: alacritty"
mkdir -p "$HOME/.config"
echo "alacritty.desktop" >"$HOME/.config/xdg-terminals.list"

# atajo Super+Return -> terminal (custom keybinding de GNOME)
kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
existing="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
if ! echo "$existing" | grep -q "custom0"; then
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
fi
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path" name "'Terminal (omakux)'" 2>/dev/null || true
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path" command "'alacritty'" 2>/dev/null || true
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path" binding "'<Super>Return'" 2>/dev/null || true

# navegador por defecto: chromium
if { has xdg-settings && [ -f /usr/share/applications/chromium.desktop ]; } || has chromium; then
  xdg-settings set default-web-browser chromium.desktop 2>/dev/null || true
fi
if [ -f "$HOME/.config/mimeapps.list" ]; then
  backup_file "$HOME/.config/mimeapps.list"
fi
mkdir -p "$HOME/.config"
cat >"$HOME/.config/mimeapps.list" <<EOF
[Default Applications]
text/html=chromium.desktop
x-scheme-handler/http=chromium.desktop
x-scheme-handler/https=chromium.desktop
EOF

# caché de fuentes del sistema
if has fc-cache && [ "$OMAKUX_DRY" != "1" ]; then
  fc-cache -f >/dev/null 2>&1 || true
fi

ok "GNOME configurado"
