#!/usr/bin/env bash
# omakux:summary Run shellcheck over every bash script in the repo
# omakux:group dev
# omakux:hidden
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck no está instalado: omakux pkg install shellcheck" >&2
  exit 1
fi

# el análisis resuelve los `source` (install/lib.sh) contra los archivos de la
# lista, pero solo si los caminos son relativos a la raíz del repo. Por eso
# se hace cd: el lint no debe depender de desde dónde lo lances.
cd "$ROOT"

# solo scripts reales: todo .sh + la CLI (bin/omakux*).
# config-themes/btop/ no es bash (formato de btop) → se excluye.
mapfile -t files < <(
  find . \
    \( -path ./.git -o -path ./config-themes/btop \) -prune -o \
    -type f \( -name '*.sh' -o -path './bin/omakux*' \) -print | sort
)

echo "shellcheck: ${#files[@]} archivos"
shellcheck "${files[@]}"
echo "ok: sin avisos"
