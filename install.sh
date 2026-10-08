#!/usr/bin/env bash
set -euo pipefail
# omakux:summary Run (or re-run) the full omakux installer
# omakux:group install

OMAKUX_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMAKUX_PATH
source "$OMAKUX_PATH/install/lib.sh"

PHASES=(check packages identification terminal gnome apps system hyprland theme ai finalize)

declare -A PHASE_FILE=(
  [check]="install/check.sh"
  [packages]="install/packages.sh"
  [identification]="install/identification.sh"
  [terminal]="install/terminal.sh"
  [gnome]="install/desktop/gnome.sh"
  [apps]="install/desktop/apps.sh"
  [system]="install/system.sh"
  [hyprland]="install/desktop/hyprland.sh"
  [theme]="install/theme.sh"
  [ai]="install/ai.sh"
  [finalize]="install/finalize.sh"
)

usage() {
  cat <<EOF
omakux installer — transforma una instalación de Ubuntu en un workstation completo

uso: install.sh [opciones]
  --only <fase>    ejecuta solo esta fase (repetible)
  --skip <fase>    salta esta fase (repetible)
  --dry-run        muestra lo que haría, sin tocar nada
  --force          re-ejecuta fases ya completadas
  -h, --help       esta ayuda

fases: ${PHASES[*]}
EOF
}

ONLY=()
SKIP=()
while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY+=("$2"); shift 2 ;;
    --skip) SKIP+=("$2"); shift 2 ;;
    --dry-run) export OMAKUX_DRY=1; shift ;;
    --force) export OMAKUX_FORCE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

# un --only/--skip con typo no debe ejecutar nada en silencio
is_phase() {
  local p="$1" s
  for s in "${PHASES[@]}"; do [ "$s" = "$p" ] && return 0; done
  return 1
}
for s in ${ONLY[@]+"${ONLY[@]}"}; do
  is_phase "$s" || die "fase desconocida: $s (válidas: ${PHASES[*]})"
done
for s in ${SKIP[@]+"${SKIP[@]}"}; do
  is_phase "$s" || die "fase desconocida: $s (válidas: ${PHASES[*]})"
done

phase_selected() {
  local p="$1" s
  if [ ${#ONLY[@]} -gt 0 ]; then
    for s in "${ONLY[@]}"; do [ "$s" = "$p" ] && return 0; done
    return 1
  fi
  for s in ${SKIP[@]+"${SKIP[@]}"}; do [ "$s" = "$p" ] && return 1; done
  return 0
}

should_skip_state() {
  local p="$1"
  [ "${OMAKUX_FORCE:-0}" = "1" ] && return 1
  state_done "phase-$p"
}

run_phase() {
  local p="$1"
  local file="$OMAKUX_PATH/${PHASE_FILE[$p]}"
  phase_selected "$p" || { log "fase '$p' omitida (--skip)"; return 0; }
  if should_skip_state "$p"; then
    log "fase '$p' ya completada (usa --force para repetir)"
    return 0
  fi
  [ -f "$file" ] || die "fase '$p': falta $file"
  log "── fase: $p ──"
  local start
  start=$(date +%s)
  # shellcheck disable=SC1090
  source "$file"
  state_mark "phase-$p"
  ok "fase '$p' completada ($(($(date +%s) - start))s)"
}

echo
printf '%somakux%s v%s — instalador para Ubuntu\n\n' "$_c_bold" "$_c_reset" "$(cat "$OMAKUX_PATH/version")"
[ "$OMAKUX_DRY" = "1" ] && warn "MODO DRY-RUN: no se hará ningún cambio"

for p in "${PHASES[@]}"; do
  run_phase "$p"
done

echo
ok "instalación completada. Cierra sesión y vuelve a entrar para aplicar todo."
echo "  · Sesiones disponibles: GNOME (por defecto) y Hyprland (selector de GDM)"
echo "  · Comandos: omakux / omakux help"
echo "  · Log: $OMAKUX_LOG"
