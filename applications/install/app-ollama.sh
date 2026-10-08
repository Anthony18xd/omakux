#!/usr/bin/env bash
# omakux:summary Instala Ollama + modelo inicial
set -euo pipefail
OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"
"$OMAKUX_PATH/bin/omakux-ai-install" ollama
if has ollama; then
  log "descargando llama3.2 (3B)…"
  run ollama pull llama3.2 || warn "descarga del modelo falló (reinténtalo: ollama pull llama3.2)"
fi
