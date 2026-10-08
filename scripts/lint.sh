#!/usr/bin/env bash
# omakux:summary Run shellcheck over every bash script in the repo
# omakux:group dev
# omakux:hidden
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# solo scripts reales: todo .sh + la CLI (bin/omakux*).
# config-themes/btop/ no es bash (formato de btop) → se excluye.
mapfile -t files < <(
  find "$ROOT" \
    \( -path "$ROOT/.git" -o -path "$ROOT/config-themes/btop" \) -prune -o \
    -type f \( -name '*.sh' -o -path "$ROOT/bin/omakux*" \) -print | sort
)

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck no está instalado: omakux pkg install shellcheck" >&2
  exit 1
fi

echo "shellcheck: ${#files[@]} archivos"
shellcheck "${files[@]}"
echo "ok: sin avisos"
