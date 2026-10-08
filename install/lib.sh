#!/usr/bin/env bash
# omakux:shared helpers for every install phase and CLI command

OMAKUX_PATH="${OMAKUX_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export OMAKUX_PATH
OMAKUX_STATE="${OMAKUX_STATE:-$HOME/.local/state/omakux}"
export OMAKUX_STATE
OMAKUX_LOG="$OMAKUX_STATE/install.log"
OMAKUX_DRY="${OMAKUX_DRY:-0}"
OMAKUX_YES="${OMAKUX_YES:-0}"

mkdir -p "$OMAKUX_STATE"

# ---------- output ----------

_c_reset=$'\033[0m'
_c_bold=$'\033[1m'
_c_dim=$'\033[2m'
_c_blue=$'\033[34m'
_c_green=$'\033[32m'
_c_yellow=$'\033[33m'
_c_red=$'\033[31m'

log() {
  printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$OMAKUX_LOG" 2>/dev/null || true
}
ok() {
  printf '%s ok %s %s\n' "$_c_green" "$_c_reset" "$*"
  printf '[%s] ok %s\n' "$(date '+%F %T')" "$*" >>"$OMAKUX_LOG" 2>/dev/null || true
}
warn() {
  printf '%s aviso%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2
  printf '[%s] warn %s\n' "$(date '+%F %T')" "$*" >>"$OMAKUX_LOG" 2>/dev/null || true
}
err() {
  printf '%serror%s %s\n' "$_c_red" "$_c_reset" "$*" >&2
  printf '[%s] error %s\n' "$(date '+%F %T')" "$*" >>"$OMAKUX_LOG" 2>/dev/null || true
}
die() {
  err "$*"
  exit 1
}

# ---------- execution (dry-run aware) ----------

run() {
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY %s%s\n' "$_c_dim" "$*" "$_c_reset"
    return 0
  fi
  "$@"
}

# run sudo with dry-run awareness (sudo resetea env → llevar DEBIAN_FRONTEND dentro)
sud() {
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY sudo %s%s\n' "$_c_dim" "$*" "$_c_reset"
    return 0
  fi
  sudo env DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true "$@"
}

confirm_sudo() {
  if [ "$OMAKUX_DRY" = "1" ]; then return 0; fi
  # sudo-rs (Ubuntu 26.04) exige TTY para `sudo -v` aunque sea NOPASSWD → usar -n
  sudo -n true || sudo -v || die "Se necesita sudo para continuar"
}

# ---------- packages ----------

apt_install() {
  [ $# -eq 0 ] && return 0
  local want=()
  local p
  for p in "$@"; do
    if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed"; then
      continue
    fi
    want+=("$p")
  done
  if [ ${#want[@]} -eq 0 ]; then
    ok "paquetes ya instalados: $*"
    return 0
  fi
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY apt install %s%s\n' "$_c_dim" "${want[*]}" "$_c_reset"
    return 0
  fi
  log "instalando: ${want[*]}"
  DEBIAN_FRONTEND=noninteractive sud apt-get install -y --no-install-recommends "${want[@]}" \
    || die "fallo instalando: ${want[*]}"
  local p
  for p in "${want[@]}"; do
    grep -qxF "$p" "$OMAKUX_STATE/installed-packages.txt" 2>/dev/null || echo "$p" >>"$OMAKUX_STATE/installed-packages.txt"
  done
  ok "${want[*]}"
}

apt_update() {
  if [ "$OMAKUX_DRY" = "1" ]; then
    echo "DRY apt-get update"
    return 0
  fi
  log "actualizando índices apt"
  sud apt-get update -qq
}

# install everything listed in a file (one package per line, # comments)
apt_install_list() {
  local file="$1" pkgs=()
  [ -f "$file" ] || die "lista de paquetes no encontrada: $file"
  while read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | tr -d '[:space:]')"
    [ -n "$line" ] && pkgs+=("$line")
  done <"$file"
  [ ${#pkgs[@]} -gt 0 ] && apt_install "${pkgs[@]}"
}

# ---------- files ----------

has() { command -v "$1" >/dev/null 2>&1; }

# copy repo file into place, backing up any existing different file once
seed() {
  local src="$1" dest="$2"
  [ -f "$src" ] || { warn "seed no encontrado: $src"; return 1; }
  if [ -f "$dest" ] && ! cmp -s "$src" "$dest"; then
    backup_file "$dest"
    if [ "$OMAKUX_DRY" = "1" ]; then
      printf '%sDRY cp %s -> %s%s\n' "$_c_dim" "$src" "$dest" "$_c_reset"
      return 0
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  elif [ ! -f "$dest" ]; then
    if [ "$OMAKUX_DRY" = "1" ]; then
      printf '%sDRY cp %s -> %s%s\n' "$_c_dim" "$src" "$dest" "$_c_reset"
      return 0
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
}

# only copy if destination missing
seed_once() {
  local src="$1" dest="$2"
  [ -f "$src" ] || { warn "seed no encontrado: $src"; return 1; }
  if [ -e "$dest" ]; then return 0; fi
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY cp %s -> %s%s\n' "$_c_dim" "$src" "$dest" "$_c_reset"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

backup_file() {
  local dest="$1"
  local rel="${dest#/}"
  local sum
  sum="$(cksum <"$dest" 2>/dev/null | awk '{print $1}')"
  local bak="$OMAKUX_STATE/backup/$rel"
  # mismo contenido ya respaldado
  [ -f "$bak" ] && [ "$(cksum <"$bak" 2>/dev/null | awk '{print $1}')" = "$sum" ] && return 0
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY backup %s%s\n' "$_c_dim" "$dest" "$_c_reset"
    return 0
  fi
  mkdir -p "$(dirname "$bak")"
  if [ -f "$bak" ]; then
    bak="$bak.$sum"
    [ -f "$bak" ] && return 0
  fi
  cp -a "$dest" "$bak"
  ok "backup: $dest -> $bak"
}

# ---------- misc ----------

state_done() { [ -f "$OMAKUX_STATE/$1.done" ]; }
state_mark() {
  [ "$OMAKUX_DRY" = "1" ] && return 0
  date '+%F %T' >"$OMAKUX_STATE/$1.done"
}

ensure_symlink() {
  local target="$1" link="$2"
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
    return 0
  fi
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY ln -sf %s %s%s\n' "$_c_dim" "$target" "$link" "$_c_reset"
    return 0
  fi
  sud ln -sf "$target" "$link"
}

add_user_to_group() {
  local group="$1" user="${2:-$USER}"
  getent group "$group" >/dev/null || return 0
  if id -nG "$user" | tr ' ' '\n' | grep -qx "$group"; then
    return 0
  fi
  if [ "$OMAKUX_DRY" = "1" ]; then
    printf '%sDRY usermod -aG %s %s%s\n' "$_c_dim" "$group" "$user" "$_c_reset"
    return 0
  fi
  sud usermod -aG "$group" "$user"
  ok "usuario $user añadido al grupo $group (efectivo tras reiniciar sesión)"
}

# --- dotfiles (manifiesto: config/dotfiles) --------------------------

# expande ~/ en un destino del manifiesto
dotfiles_dest() {
  printf '%s' "${1/#\~/$HOME}"
}

# recorre el manifiesto; llama a: <callback> <modo> <src> <destino absoluto>
dotfiles_each() {
  local cb="$1" modo src dest
  [ -f "$OMAKUX_PATH/config/dotfiles" ] || {
    warn "manifiesto no encontrado: $OMAKUX_PATH/config/dotfiles"
    return 1
  }
  while read -r modo src dest; do
    case "$modo" in '' | '#'*) continue ;; esac
    [ -n "${dest:-}" ] || continue
    "$cb" "$modo" "$src" "$(dotfiles_dest "$dest")"
  done <"$OMAKUX_PATH/config/dotfiles"
}

# dónde guarda omakux el último render de cada destino (para poder difuminar)
# $OMAKUX_STATE/rendered/<ruta relativa a $HOME>
dotfiles_snapshot() {
  case "$1" in
    "$HOME"/*) printf '%s/rendered/%s' "$OMAKUX_STATE" "${1#"$HOME"/}" ;;
    *) return 1 ;;
  esac
}

# ruta relativa de un destino (para copiarlo dentro de un export)
dotfiles_rel() {
  local dest="$1"
  case "$dest" in
    "$HOME"/*) printf '%s' "${dest#"$HOME"/}" ;;
    /*) printf '%s' "${dest#/}" ;;
    *) printf '%s' "$dest" ;;
  esac
}

# estado de un dotfile: igual | modificada | falta | pendiente
dotfiles_status() {
  local modo="$1" src="$2" dest="$3" ref=""
  [ -f "$dest" ] || { echo "falta"; return 0; }
  case "$modo" in
    seed) ref="$OMAKUX_PATH/$src" ;;
    render)
      ref="$(dotfiles_snapshot "$dest" 2>/dev/null || true)"
      if [ -z "$ref" ] || [ ! -f "$ref" ]; then
        echo "pendiente"
        return 0
      fi
      ;;
    *) echo "desconocido"; return 0 ;;
  esac
  if cmp -s "$ref" "$dest"; then
    echo "igual"
  else
    echo "modificada"
  fi
}
