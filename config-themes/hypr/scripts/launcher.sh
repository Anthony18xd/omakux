#!/usr/bin/env bash
# omakux — launcher de aplicaciones (wofi)
set -euo pipefail
exec wofi --show drun --prompt "buscar…" --insensitive --allow-images
