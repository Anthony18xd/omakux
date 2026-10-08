#!/usr/bin/env bash
# omakux:summary Uninstall omakux (restores backups, removes packages)
# omakux:group install
set -euo pipefail

OMAKUX_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMAKUX_PATH="${OMAKUX_PATH:-$(dirname "$OMAKUX_BIN")}"
export OMAKUX_PATH
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/lib.sh"

echo
echo "Esto va a:"
echo "  1. restaurar tus configs originales (desde $OMAKUX_STATE/backup)"
echo "  2. eliminar los paquetes que instaló omakux"
echo "  3. restaurar tu shell original"
echo "  4. quitar el symlink /usr/local/bin/omakux"
echo "  NO borra snapshots de timeshift ni tu repo"
echo

if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
  gum confirm "¿Desinstalar omakux?" || exit 0
else
  printf '¿Desinstalar omakux? [s/N] '
  read -r ans
  case "$ans" in s | S | si | sí) ;; *) exit 0 ;; esac
fi

confirm_sudo

# 1. restaurar backups (solo los originales, sin sufijo de hash)
if [ -d "$OMAKUX_STATE/backup" ]; then
  log "restaurando configs originales"
  while IFS= read -r bak; do
    rel="${bak#"$OMAKUX_STATE/backup/"}"
    case "$rel" in
      *.????????) continue ;; # backups con sufijo .<cksum>
    esac
    dest="/$rel"
    [ -f "$dest" ] || mkdir -p "$(dirname "$dest")"
    if cp -a "$bak" "$dest"; then ok "restaurado: $dest"; else warn "no se pudo restaurar $dest"; fi
  done < <(find "$OMAKUX_STATE/backup" -type f)
fi

# 2. borrar semillas creadas sin backup previo (no existían antes)
seeds=(
  "$HOME/.config/xdg-terminals.list"
  "$HOME/.config/xdg-desktop-portal/Hyprland-portals.conf"
)
for s in "${seeds[@]}"; do
  rel="${s#/}"
  if [ -f "$OMAKUX_STATE/backup/$rel" ]; then continue; fi
  rm -f "$s"
done

# 3. paquetes instalados por omakux
if [ -f "$OMAKUX_STATE/installed-packages.txt" ]; then
  log "eliminando paquetes instalados por omakux"
  mapfile -t pkgs <"$OMAKUX_STATE/installed-packages.txt"
  if [ ${#pkgs[@]} -gt 0 ]; then
    sud apt-get remove -y "${pkgs[@]}" >/dev/null 2>&1 || warn "algunos paquetes no se pudieron quitar"
    ok "${#pkgs[@]} paquetes eliminados"
  fi
fi

# 4. snaps/flatpaks registrados
if [ -f "$OMAKUX_STATE/installed-snaps.txt" ]; then
  while read -r s; do
    [ -n "$s" ] || continue
    sud snap remove "$s" >/dev/null 2>&1 || true
  done <"$OMAKUX_STATE/installed-snaps.txt"
fi
if [ -f "$OMAKUX_STATE/installed-flatpaks.txt" ]; then
  while read -r f; do
    [ -n "$f" ] || continue
    sud flatpak uninstall -y "$f" >/dev/null 2>&1 || true
  done <"$OMAKUX_STATE/installed-flatpaks.txt"
fi

# 5. shell original
if [ -f "$OMAKUX_STATE/original-shell" ]; then
  orig="$(cat "$OMAKUX_STATE/original-shell")"
  if [ -n "$orig" ] && [ -x "$orig" ]; then
    chsh -s "$orig" "$USER" 2>/dev/null && ok "shell restaurado: $orig"
  fi
fi

# 6. symlink
if [ -L /usr/local/bin/omakux ]; then
  sud rm -f /usr/local/bin/omakux
  ok "symlink eliminado"
fi

echo
ok "omakux desinstalado"
echo "  · tus configs originales están en $OMAKUX_STATE/backup"
echo "  · el repo sigue en $OMAKUX_PATH (borra con: rm -rf $OMAKUX_PATH)"
echo "  · snapshots: omakux snapshot list (timeshift se mantiene)"
