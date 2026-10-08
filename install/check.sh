#!/usr/bin/env bash
# omakux:summary Validate this machine can run omakux
# omakux:group install
# sourced by install.sh — do not execute directly

# --- OS ---
[ -r /etc/os-release ] || die "no se pudo leer /etc/os-release"
# shellcheck disable=SC1091
source /etc/os-release
OMAKUX_OS_ID="${ID:-}"
OMAKUX_OS_VER="${VERSION_ID:-}"

if [ "$OMAKUX_OS_ID" != "ubuntu" ]; then
  die "omakux solo soporta Ubuntu (detectado: ${DESCRIBO:-$OMAKUX_OS_ID})"
fi
major="${OMAKUX_OS_VER%%.*}"
if [ -z "$major" ] || [ "$major" -lt 24 ]; then
  die "se necesita Ubuntu 24.04 o superior (detectado: $OMAKUX_OS_VER)"
fi
ok "Ubuntu $OMAKUX_OS_VER ($(uname -m))"

# --- arch ---
case "$(uname -m)" in
  x86_64 | aarch64) ;;
  *) die "arquitectura no soportada: $(uname -m)" ;;
esac

# --- disk space (>= 10G free on /) ---
avail_k=$(df -Pk / | awk 'NR==2 {print $4}')
if [ "$avail_k" -lt $((10 * 1024 * 1024)) ]; then
  die "menos de 10 GB libres en / (${avail_k} KB)"
fi
ok "espacio en disco: $((avail_k / 1024 / 1024)) GB libres"

# --- network ---
if has curl; then
  curl -fsSL -m 10 -o /dev/null https://archive.ubuntu.com >/dev/null 2>&1 ||
    warn "sin conexión a internet verificada (apt podría fallar)"
else
  warn "curl no disponible; se comprobará la red al instalar"
fi

# --- sudo ---
if [ "$OMAKUX_DRY" = "1" ]; then
  log "dry-run: se omite la comprobación de sudo"
else
  confirm_sudo
  ok "sudo disponible"
fi

# --- session info ---
log "sesión actual: ${XDG_CURRENT_DESKTOP:-desconocida} / ${XDG_SESSION_TYPE:-?}"
case "${XDG_SESSION_TYPE:-}" in
  wayland) ok "Wayland activo" ;;
  x11) warn "estás en X11; algunos ajustes visuales aplican solo en Wayland" ;;
esac

# --- filesystem ---
root_fs="$(findmnt -no FSTYPE / 2>/dev/null || echo "?")"
log "filesystem raíz: $root_fs"
if [ "$root_fs" = "btrfs" ]; then
  ok "btrfs detectado: snapper disponible como alternativa"
else
  log "snapshots usarán timeshift en modo rsync (filesystem $root_fs)"
fi

# --- GPU ---
if lspci 2>/dev/null | grep -qi nvidia; then
  if has nvidia-smi; then
    ok "GPU NVIDIA detectada (driver $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo '?'))"
  else
    warn "GPU NVIDIA sin nvidia-smi: instala los drivers antes de usar Hyprland"
  fi
fi
lspci 2>/dev/null | grep -qi 'VGA compatible controller' && log "GPU listadas: $(lspci | grep 'VGA compatible' | cut -d: -f3 | sed 's/^ //' | tr '\n' ';' | sed 's/;$//')"

export OMAKUX_OS_ID OMAKUX_OS_VER root_fs
