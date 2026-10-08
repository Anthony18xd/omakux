#!/usr/bin/env bash
# shellcheck disable=SC2317
# ^ "return || exit": fallback para cuando el script se ejecuta en vez de sourcearse
# omakux:summary Collect name/email for git identity
# omakux:group install
# sourced by install.sh — do not execute directly

git_name="$(git config --global user.name 2>/dev/null || true)"
git_email="$(git config --global user.email 2>/dev/null || true)"

if [ -n "$git_name" ] && [ -n "$git_email" ]; then
  ok "identidad git ya configurada: $git_name <$git_email>"
  return 0 2>/dev/null || exit 0
fi

if has gum && [ "$OMAKUX_YES" != "1" ]; then
  git_name="$(gum input --prompt "Nombre: " --value "${git_name:-$USER}" --limit 60 --width 40)"
  git_email="$(gum input --prompt "Email: " --value "${git_email:-}" --placeholder "tu@email.com" --limit 80 --width 40)"
fi

git_name="${git_name:-$USER}"
git_email="${git_email:-$USER@$(hostname)}"

if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY git config --global user.name '$git_name' / user.email '$git_email'"
else
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor "nvim"
  ok "git configurado: $git_name <$git_email>"
fi
