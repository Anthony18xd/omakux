#!/usr/bin/env bats
# Fase 3: config/dotfiles como producto (list, diff, export, import)

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

MANIFEST="$OMAKUX_ROOT/config/dotfiles"
THEMES_MAN="$OMAKUX_ROOT/config-themes/manifest"

# destinos que instala el instalador via seed/seed_once (rutas literales)
seeded_dests() {
  grep -hE '^\s*seed(_once)? ' \
    "$OMAKUX_ROOT"/install/terminal.sh "$OMAKUX_ROOT"/install/desktop/hyprland.sh \
    "$OMAKUX_ROOT"/install/terminal/*.sh 2>/dev/null |
    grep -oE '"\$HOME/[^"]+"' |
    grep -vF '$(basename' |
    sed -E 's/^"\$HOME\///; s/"$//' |
    sort -u
}

# simula la fase de instalación: copia los seeds del manifiesto al HOME
install_seeds() {
  local modo src dest
  while read -r modo src dest; do
    [ "$modo" = "seed" ] || continue
    mkdir -p "$(dirname "$HOME/${dest#\~/}")"
    cp "$OMAKUX_ROOT/$src" "$HOME/${dest#\~/}"
  done <"$MANIFEST"
}

# destinos tipo ~/ del manifest de temas
rendered_dests() {
  awk '$1 != "#" && $1 != "" && $2 ~ /^~\// { print $2 }' "$THEMES_MAN"
}

manifest_dests() {
  awk '$1 != "#" && $1 != "" { print $3 }' "$MANIFEST"
}

@test "todos los destinos seed del instalador estan en config/dotfiles" {
  local d
  for d in $(seeded_dests); do
    manifest_dests | grep -qF "~/$d" || {
      echo "seed sin manifiesto: ~/$d"
      return 1
    }
  done
}

@test "todos los destinos render del theme-set estan en config/dotfiles" {
  local d
  for d in $(rendered_dests); do
    manifest_dests | grep -qF "$d" || {
      echo "render sin manifiesto: $d"
      return 1
    }
  done
}

@test "todo seed del manifiesto lo instala realmente el instalador" {
  local modo src dest
  while read -r modo src dest; do
    [ "$modo" = "seed" ] || continue
    seeded_dests | grep -qF "${dest#\~/}" || {
      echo "manifiesto marca seed pero el instalador no lo copia: $dest"
      return 1
    }
  done <"$MANIFEST"
}

@test "config list marca render reciente como igual y edicion como modificada" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  run bash "$OMAKUX_ROOT/bin/omakux-config-list"
  [ "$status" -eq 0 ]
  [[ "$output" == *"igual"* ]]

  local f="$HOME/.config/alacritty/alacritty.toml"
  echo "# editado a mano" >>"$f"

  run bash "$OMAKUX_ROOT/bin/omakux-config-list"
  [ "$status" -eq 0 ]
  [[ "$output" == *"modificada"* ]]
}

@test "config list distingue falta y filtra por ruta" {
  run bash "$OMAKUX_ROOT/bin/omakux-config-list"
  [ "$status" -eq 0 ]
  [[ "$output" == *"falta"* ]]

  run bash "$OMAKUX_ROOT/bin/omakux-config-list" nvim
  [ "$status" -eq 0 ]
  [[ "$output" == *"ningún dotfile coincide"* ]]
}

@test "config diff sale 0 cuando todo coincide" {
  install_seeds
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  run bash "$OMAKUX_ROOT/bin/omakux-config-diff"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sin diferencias"* ]]
}

@test "config diff muestra los cambios y sale 1" {
  install_seeds
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  echo "# toqueteo posterior al render" >>"$HOME/.config/waybar/style.css"
  echo "set -g @omakux 1" >>"$HOME/.config/hypr/local.conf"

  run bash "$OMAKUX_ROOT/bin/omakux-config-diff"
  [ "$status" -eq 1 ]
  [[ "$output" == *"waybar/style.css"* ]]
  [[ "$output" == *"hypr/local.conf"* ]]
  [[ "$output" == *"@omakux"* ]]

  run bash "$OMAKUX_ROOT/bin/omakux-config-diff" local.conf
  [ "$status" -eq 1 ]
  [[ "$output" == *"local.conf"* ]]
  [[ "$output" != *"waybar/style.css"* ]]
}

@test "config export copia files, manifest y hace commit git" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  echo "set -g @omakux 1" >>"$HOME/.config/hypr/local.conf"

  run bash "$OMAKUX_ROOT/bin/omakux-config-export" "$SANDBOX/export"
  [ "$status" -eq 0 ]

  [ -f "$SANDBOX/export/files/.config/hypr/local.conf" ]
  [ -f "$SANDBOX/export/files/.config/alacritty/alacritty.toml" ]
  [ -f "$SANDBOX/export/omakux-dotfiles.manifest" ]
  [ -f "$SANDBOX/export/README.md" ]
  grep -q '@omakux' "$SANDBOX/export/files/.config/hypr/local.conf"
  git -C "$SANDBOX/export" log --oneline >/dev/null 2>&1
}

@test "config import restaura un export (con backup previo)" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  echo "set -g @omakux 1" >>"$HOME/.config/hypr/local.conf"

  run bash "$OMAKUX_ROOT/bin/omakux-config-export" "$SANDBOX/export"
  [ "$status" -eq 0 ]

  # descuadrar un destino y restaurarlo
  echo "GARBAGE" >"$HOME/.config/hypr/local.conf"
  run env OMAKUX_YES=1 bash "$OMAKUX_ROOT/bin/omakux-config-import" "$SANDBOX/export"
  [ "$status" -eq 0 ]
  grep -q '@omakux' "$HOME/.config/hypr/local.conf"
  [ -n "$(find "$OMAKUX_STATE/backup" -name 'local.conf' 2>/dev/null)" ]
}

@test "config export en dry-run no escribe nada" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  run env OMAKUX_DRY=1 bash "$OMAKUX_ROOT/bin/omakux-config-export" "$SANDBOX/dryx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY export"* ]]
  [ ! -e "$SANDBOX/dryx" ]
}

@test "config import rechaza un directorio que no es export" {
  mkdir -p "$SANDBOX/bogus"
  run bash "$OMAKUX_ROOT/bin/omakux-config-import" "$SANDBOX/bogus"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no parece un export"* ]]
}