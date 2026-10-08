#!/usr/bin/env bash
# omakux:summary Install shell, editor, languages and dev tooling
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo

# --- apt: terminal tools ---
apt_install_list "$OMAKUX_PATH/install/packages/terminal.apt"

# --- fish as default shell ---
if has fish; then
  fish_path="$(command -v fish)"
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  [ -f "$OMAKUX_STATE/original-shell" ] || echo "$current_shell" >"$OMAKUX_STATE/original-shell"
  if [ "$SHELL" != "$fish_path" ] && [ "$current_shell" != "$fish_path" ]; then
    if grep -qxF "$fish_path" /etc/shells; then
      if [ "$OMAKUX_DRY" = "1" ]; then
        log "DRY chsh -s $fish_path"
      else
        sud chsh -s "$fish_path" "$USER" || warn "no se pudo cambiar el shell (ejecuta: chsh -s $fish_path)"
        ok "shell por defecto: fish (reinicia sesión para aplicar)"
      fi
    else
      sud bash -c "echo '$fish_path' >> /etc/shells"
      sud chsh -s "$fish_path" "$USER" || true
    fi
  else
    ok "shell por defecto ya es fish"
  fi
fi

# --- fish config ---
seed "$OMAKUX_PATH/config/fish/config.fish" "$HOME/.config/fish/config.fish"

# --- completions de la CLI (se regeneran solas con omakux completion install) ---
bash "$OMAKUX_PATH/bin/omakux-completion" install bash || warn "no se pudo instalar la completion de bash"
if has fish; then
  bash "$OMAKUX_PATH/bin/omakux-completion" install fish || warn "no se pudo instalar la completion de fish"
fi

# --- tmux ---
seed "$OMAKUX_PATH/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# --- starship (themed later by theme-set) ---
mkdir -p "$HOME/.config"
seed_once "$OMAKUX_PATH/config-themes/starship/starship.toml" "$HOME/.config/starship.toml"

# --- bat theme dir / eza ---
mkdir -p "$HOME/.config/bat"

# --- yazi (no está en apt: binario oficial) ---
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/terminal/yazi.sh"

# --- mise: versiones de lenguajes ---
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/terminal/mise.sh"

# --- LazyVim ---
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/terminal/lazyvim.sh"

# --- docker ---
# shellcheck disable=SC1091
source "$OMAKUX_PATH/install/terminal/docker.sh"

# --- CLI en ~/.local/bin ---
mkdir -p "$HOME/.local/bin"

ok "terminal y dev tooling instalados"
