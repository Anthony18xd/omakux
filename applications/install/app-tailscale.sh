#!/usr/bin/env bash
# omakux:summary Instala Tailscale (VPN en malla)
set -euo pipefail
OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"
confirm_sudo
if has tailscale; then
  ok "tailscale ya instalado"
else
  log "instalando tailscale (repo oficial)"
  curl -fsSL -m 30 https://tailscale.com/install.sh | sh >/dev/null 2>&1 || die "fallo tailscale"
  ok "tailscale instalado — 'sudo tailscale up' para conectar"
fi
