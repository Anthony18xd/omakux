#!/usr/bin/env bash
# omakux:summary Install mise (language version manager) + default runtimes
# omakux:group install
# sourced by terminal.sh — do not execute directly

if [ ! -x "$HOME/.local/bin/mise" ] && ! has mise; then
  log "instalando mise"
  if [ "$OMAKUX_DRY" = "1" ]; then
    log "DRY curl https://mise.run | sh"
  else
    curl -fsSL -m 30 https://mise.run | MISE_INSTALL_DIR="$HOME/.local/bin" sh ||
      warn "fallo la instalación de mise"
  fi
fi

MISE="$HOME/.local/bin/mise"
[ -x "$MISE" ] || MISE="$(command -v mise || true)"
if [ -n "$MISE" ] && [ "$OMAKUX_DRY" != "1" ]; then
  ok "mise $($MISE --version 2>/dev/null | head -1)"
  # runtime por defecto: node LTS (claude code, codex, etc. lo necesitan)
  if ! "$MISE" ls --installed node >/dev/null 2>&1 || [ -z "$("$MISE" ls --installed node 2>/dev/null)" ]; then
    log "instalando node LTS vía mise"
    "$MISE" use --global node@lts || warn "no se pudo instalar node (reinténtalo: mise use -g node@lts)"
  fi
  # python por defecto
  if [ -z "$("$MISE" ls --installed python 2>/dev/null)" ]; then
    "$MISE" use --global python@latest || warn "no se pudo instalar python"
  fi
  "$MISE" reshim || true
  ok "runtimes: node=$("$MISE" current node 2>/dev/null || echo '?') python=$("$MISE" current python 2>/dev/null || echo '?')"
else
  [ "$OMAKUX_DRY" = "1" ] && log "DRY mise: node@lts + python@latest"
fi
