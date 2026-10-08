#!/usr/bin/env bash
# omakux:summary Instala Obsidian (flatpak)
set -euo pipefail
OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"
confirm_sudo
if flatpak info md.obsidian.Obsidian >/dev/null 2>&1; then
  ok "Obsidian ya instalado"
else
  sud flatpak install -y flathub md.obsidian.Obsidian &&
    echo "md.obsidian.Obsidian" >>"$OMAKUX_STATE/installed-flatpaks.txt"
  ok "Obsidian instalado"
fi
