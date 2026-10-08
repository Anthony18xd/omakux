#!/usr/bin/env bash
# omakux:summary Apply (or re-apply) the active theme
# omakux:group install
# sourced by install.sh — do not execute directly

default_theme="${OMAKUX_DEFAULT_THEME:-tokyonight}"
active="$(cat "$OMAKUX_STATE/theme" 2>/dev/null || true)"
active="${active:-$default_theme}"

if [ ! -d "$OMAKUX_PATH/themes/$active" ]; then
  warn "tema activo '$active' no existe; usando $default_theme"
  active="$default_theme"
fi

"$OMAKUX_PATH/bin/omakux-theme-set" "$active"
