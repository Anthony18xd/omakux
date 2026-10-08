#!/usr/bin/env bash
# omakux:summary Install the base apt package set
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo
apt_update

log "paquetes base del sistema"
apt_install_list "$OMAKUX_PATH/install/packages/base.apt"

# flatpak + flathub (para Signal, Spotify, apps sin .deb)
if [ "$OMAKUX_DRY" != "1" ]; then
  if has flatpak; then
    sud flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo ||
      warn "no se pudo añadir flathub"
    ok "remoto flathub configurado"
  fi
  # CLI en PATH
  ensure_symlink "$OMAKUX_PATH/bin/omakux" /usr/local/bin/omakux
fi

ok "base de paquetes lista"
