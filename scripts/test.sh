#!/usr/bin/env bash
# omakux:summary Run the whole test suite (bats) plus lint
# omakux:group dev
# omakux:hidden
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
  echo "falta bats: omakux pkg install bats" >&2
  exit 1
fi

fail=0
if command -v shellcheck >/dev/null 2>&1; then
  bash "$ROOT/scripts/lint.sh" || fail=1
else
  echo "aviso: shellcheck no instalado, se omite el lint" >&2
fi

echo
bats "$ROOT/tests" || fail=1

exit "$fail"
