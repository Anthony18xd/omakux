#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ "return || exit": fallback para cuando el script se ejecuta en vez de sourcearse
# omakux:summary Install LazyVim Neovim distribution
# omakux:group install
# sourced by terminal.sh — do not execute directly

NVIM_CFG="$HOME/.config/nvim"

if [ -d "$NVIM_CFG" ]; then
  ok "configuración de nvim ya presente (LazyVim o personalizada)"
  return 0 2>/dev/null || exit 0
fi

has nvim || { warn "nvim no instalado; se omite LazyVim"; return 0 2>/dev/null || exit 0; }

log "instalando LazyVim (starter)"
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY git clone lazyvim starter -> $NVIM_CFG"
  return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.config"
git clone --filter=blob:none --branch=main https://github.com/LazyVim/starter.git "$NVIM_CFG" >/dev/null 2>&1 ||
  warn "fallo el clone de LazyVim starter"
rm -rf "$NVIM_CFG/.git"

if [ -d "$NVIM_CFG" ]; then
  log "sincronizando plugins de LazyVim (la primera vez tarda)"
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "Lazy! sync falló; se completará en el primer arranque"
  ok "LazyVim instalado en $NVIM_CFG"
fi
