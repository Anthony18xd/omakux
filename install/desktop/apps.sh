#!/usr/bin/env bash
# omakux:summary Install everyday GUI applications
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo

# multiverse (steam y codecs)
if ! dpkg -l | grep -q "^ii  software-properties-common"; then apt_install software-properties-common; fi
if [ "$OMAKUX_DRY" != "1" ]; then
  if ! grep -rq "^deb .*multiverse" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    log "habilitando multiverse"
    sud add-apt-repository -y multiverse >/dev/null 2>&1 || warn "no se pudo habilitar multiverse"
    apt_update
  fi
fi

apt_install_list "$OMAKUX_PATH/install/packages/apps.apt"

# --- chromium (snap oficial) ---
if ! snap list chromium >/dev/null 2>&1; then
  if [ "$OMAKUX_DRY" = "1" ]; then
    log "DRY snap install chromium"
  else
    log "instalando chromium (snap)"
    if sud snap install chromium 2>/dev/null; then
      echo "chromium" >>"$OMAKUX_STATE/installed-snaps.txt"
    else
      warn "chromium: instálalo con 'snap install chromium'"
    fi
  fi
fi

# --- Signal (flatpak oficial) ---
if ! flatpak info org.signal.Signal >/dev/null 2>&1; then
  if [ "$OMAKUX_DRY" = "1" ]; then
    log "DRY flatpak install flathub org.signal.Signal"
  else
    log "instalando Signal (flatpak)"
    if sud flatpak install -y flathub org.signal.Signal 2>/dev/null; then
      echo "org.signal.Signal" >>"$OMAKUX_STATE/installed-flatpaks.txt"
    else
      warn "Signal falló (reinténtalo: flatpak install flathub org.signal.Signal)"
    fi
  fi
fi

# --- Spotify (snap oficial) ---
if ! snap list spotify >/dev/null 2>&1; then
  if [ "$OMAKUX_DRY" = "1" ]; then
    log "DRY snap install spotify"
  else
    log "instalando Spotify (snap)"
    if sud snap install spotify 2>/dev/null; then
      echo "spotify" >>"$OMAKUX_STATE/installed-snaps.txt"
    else
      warn "Spotify falló (reinténtalo: snap install spotify)"
    fi
  fi
fi

# escritorios de flatpak en el menú de GNOME
if [ "$OMAKUX_DRY" != "1" ] && has update-desktop-database; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

ok "apps de escritorio instaladas"
