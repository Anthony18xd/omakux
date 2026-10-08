#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ "return || exit": fallback para cuando el script se ejecuta en vez de sourcearse
# omakux:summary Install yazi file manager from official GitHub releases
# omakux:group install
# sourced by terminal.sh — do not execute directly

if has yazi; then
  ok "yazi ya instalado ($(yazi --version 2>/dev/null | head -1))"
  return 0 2>/dev/null || exit 0
fi

ver="$( { curl -fsSL -m 15 https://api.github.com/repos/sxyazi/yazi/releases/latest 2>/dev/null || true; } | jq -r '.tag_name // empty' | sed 's/^v//' || true )"
if [ -z "$ver" ]; then
  warn "no se pudo obtener la última versión de yazi; se omite (puedes instalarlo con: omakux pkg install yazi-bin)"
  return 0 2>/dev/null || exit 0
fi

arch="$(uname -m)"
case "$arch" in
  x86_64) ya_arch="x86_64" ;;
  aarch64) ya_arch="aarch64" ;;
  *) warn "yazi: arquitectura $arch no soportada"; return 0 2>/dev/null || exit 0 ;;
esac

tmp="$(mktemp -d)"
url="https://github.com/sxyazi/yazi/releases/download/v$ver/yazi-$ya_arch-unknown-linux-gnu.zip"
log "descargando yazi v$ver"
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY curl -L $url"
else
  if curl -fsSL -m 60 -o "$tmp/yazi.zip" "$url"; then
    unzip -qo "$tmp/yazi.zip" -d "$tmp"
    mkdir -p "$HOME/.local/bin"
    if [ -d "$tmp/yazi-x86_64-unknown-linux-gnu" ] || [ -d "$tmp" ]; then
      bin="$(find "$tmp" -maxdepth 2 -type f -name yazi | head -1)"
      if [ -n "$bin" ]; then
        cp "$bin" "$HOME/.local/bin/yazi"
        # ya + yfm wrappers
        printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$HOME/.local/bin/yazi" >"$HOME/.local/bin/ya"
        chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"
        # shellcheck disable=SC1091
        [ -f "$OMAKUX_PATH/install/lib.sh" ] && source "$OMAKUX_PATH/install/lib.sh"
        echo "yazi (github v$ver)" >>"$OMAKUX_STATE/installed-packages.txt"
        ok "yazi v$ver -> ~/.local/bin/yazi"
      else
        warn "yazi: binario no encontrado en el zip"
      fi
    fi
  else
    warn "fallo la descarga de yazi ($url)"
  fi
fi
rm -rf "$tmp"

# config semilla
seed "$OMAKUX_PATH/config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml" || true
