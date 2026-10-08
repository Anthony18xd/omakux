#!/usr/bin/env bash
# omakux:summary Instala Discord (flatpak)
set -euo pipefail
OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"
confirm_sudo
if flatpak info com.discordapp.Discord >/dev/null 2>&1; then
  ok "Discord ya instalado"
else
  sud flatpak install -y flathub com.discordapp.Discord &&
    echo "com.discordapp.Discord" >>"$OMAKUX_STATE/installed-flatpaks.txt"
  ok "Discord instalado"
fi
