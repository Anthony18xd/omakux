#!/usr/bin/env bash
# omakux:summary Instala Brave Browser (snap)
set -euo pipefail
OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"
confirm_sudo
if snap list brave >/dev/null 2>&1; then
  ok "Brave ya instalado"
else
  sud snap install brave && echo "brave" >>"$OMAKUX_STATE/installed-snaps.txt"
  ok "Brave instalado"
fi
