#!/usr/bin/env bash
set -euo pipefail
# omakux:summary One-line installer: curl -fsSL <repo>/boot.sh | bash
# omakux:group install

DEST="${OMAKUX_PATH:-$HOME/.local/share/omakux}"
REPO="${OMAKUX_REPO:-https://github.com/anthony/omakux.git}"
BRANCH="${OMAKUX_BRANCH:-main}"

# Running from inside a local checkout? Just use it.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SRC" ] && [ -f "$SRC/install.sh" ] && [ -d "$SRC/bin" ]; then
  exec bash "$SRC/install.sh" "$@"
fi

if ! command -v git >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
fi

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone --depth 1 -b "$BRANCH" "$REPO" "$DEST"
fi

exec bash "$DEST/install.sh" "$@"
