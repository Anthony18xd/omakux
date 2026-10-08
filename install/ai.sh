#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ "return || exit": fallback para cuando el script se ejecuta en vez de sourcearse
# omakux:summary Install AI coding agents (claude, codex, ollama)
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# npm viene de mise (fase terminal)
if ! command -v npm >/dev/null 2>&1; then
  warn "npm no disponible (mise/node falló); se omiten los agentes CLI"
  return 0 2>/dev/null || exit 0
fi

"$OMAKUX_PATH/bin/omakux-ai-install" claude
"$OMAKUX_PATH/bin/omakux-ai-install" codex

# ollama (runtime local de LLM)
if ! command -v ollama >/dev/null 2>&1; then
  log "instalando ollama"
  if [ "$OMAKUX_DRY" = "1" ]; then
    log "DRY curl -fsSL https://ollama.com/install.sh | sh"
  else
    curl -fsSL -m 30 https://ollama.com/install.sh | sh >/dev/null 2>&1 ||
      warn "ollama falló (reinténtalo: omakux ai install ollama)"
  fi
fi

ok "agentes IA: claude, codex, ollama (voxtype: omakux ai install voxtype)"
