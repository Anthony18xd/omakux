#!/usr/bin/env bats
# motor de temas: render, dry-run y validación de paletas

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "theme set renderiza configs sin placeholders sueltos" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  local f
  for f in \
    "$HOME/.config/alacritty/alacritty.toml" \
    "$HOME/.config/waybar/style.css" \
    "$HOME/.config/wofi/style.css" \
    "$HOME/.config/hypr/hyprlock.conf" \
    "$HOME/.config/dunst/dunst.conf" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/tmux/colors.conf" \
    "$HOME/.config/btop/themes/omakux.theme"; do
    [ -f "$f" ]
    ! grep -q '{{' "$f"
  done
}

@test "theme set usa los colores del tema elegido" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  # color_bg del tema debe aparecer en algún render
  local bg
  bg="$(grep -m1 '^color_bg=' "$OMAKUX_ROOT/themes/gruvbox-dark/colors.sh" | cut -d= -f2- | tr -d '"')"
  grep -qi "$bg" "$HOME/.config/alacritty/alacritty.toml" "$HOME/.config/waybar/style.css"
}

@test "theme set deja el estado consistente (tema + wallpaper)" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [ "$(cat "$OMAKUX_STATE/theme")" = "gruvbox-dark" ]
  [ -e "$OMAKUX_STATE/wallpapers/active.png" ]
}

@test "theme set toca gsettings (fondo y esquema) via stub, no la sesión real" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" catppuccin-mocha
  [ "$status" -eq 0 ]
  grep -q 'org.gnome.desktop.background picture-uri' "$STUB_LOG"
  grep -q 'color-scheme' "$STUB_LOG"
}

@test "theme set en dry-run no escribe nada" {
  export OMAKUX_DRY=1
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY render"* ]]
  [ ! -e "$HOME/.config/alacritty/alacritty.toml" ]
  [ ! -e "$OMAKUX_STATE/theme" ]
}

@test "theme set con nombre desconocido falla y no toca el estado" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" no-existe
  [ "$status" -eq 1 ]
  [[ "$output" == *"tema no encontrado"* ]]
  [ ! -e "$OMAKUX_STATE/theme" ]
}

@test "se puede volver al tema original" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" tokyonight
  [ "$status" -eq 0 ]
  [ "$(cat "$OMAKUX_STATE/theme")" = "tokyonight" ]
}

@test "theme list marca el activo y lista los 3 por defecto" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  run bash "$OMAKUX_ROOT/bin/omakux-theme-list"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tokyonight"* ]]
  [[ "$output" == *"catppuccin-mocha"* ]]
  [[ "$output" == *"gruvbox-dark"* ]]
}

@test "toda paleta define la lista mínima de colores" {
  local required="bg fg surface accent muted red green yellow blue magenta cyan orange"
  local dir var
  for dir in "$OMAKUX_ROOT"/themes/*/; do
    for var in $required; do
      grep -q "^color_${var}=" "$dir/colors.sh" || {
        echo "falta color_$var en $dir"
        return 1
      }
    done
  done
}

@test "toda paleta define la primera línea (descripción del tema)" {
  local dir
  for dir in "$OMAKUX_ROOT"/themes/*/; do
    head -1 "$dir/colors.sh" | grep -q '^# .\+'
  done
}
