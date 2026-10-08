#!/usr/bin/env bats
# Fase 1: manifest declarativo, integraciones, theme lint y theme live

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  unset OMAKUX_MANIFEST OMAKUX_LIVE_INTERVAL 2>/dev/null || true
  [ -n "${live_pid:-}" ] && kill "$live_pid" 2>/dev/null
  rm -rf "$OMAKUX_ROOT/themes/_broken" "$OMAKUX_ROOT/themes/_live-test"
  teardown_sandbox
}

@test "theme set pinta gtk 3 y 4 con tema, iconos y cursor del sistema" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  local f
  for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -f "$f" ]
    grep -q 'gtk-theme-name=Yaru-wartybrown-dark' "$f"
    grep -q 'gtk-icon-theme-name=Yaru-wartybrown-dark' "$f"
    grep -q 'gtk-cursor-theme-name=Yaru' "$f"
    grep -q 'gtk-application-prefer-dark-theme=true' "$f"
    ! grep -q '{{' "$f"
  done
}

@test "gsettings recibe también icon-theme, cursor-theme y accent" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  grep -q "interface icon-theme" "$STUB_LOG"
  grep -q "interface cursor-theme" "$STUB_LOG"
  grep -q "accent-color 'orange'" "$STUB_LOG"
}

@test "un requisito cmd: con varias opciones se cumple si existe alguna" {
  printf 'hypr/hyprlock.conf ~/.config/hypr/hyprlock.conf cmd:hyprlock,hyprland\n' \
    >"$SANDBOX/manifest"
  export OMAKUX_MANIFEST="$SANDBOX/manifest"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/hypr/hyprlock.conf" ]
  [[ "$output" == *"1 renderizados, 0 omitidos"* ]]
}

@test "un requisito incumplido omite el target sin romper nada" {
  printf 'gtk/settings.ini ~/.config/omakux-req/x.ini dir:/no/existe/omakux\n' \
    >"$SANDBOX/manifest"
  export OMAKUX_MANIFEST="$SANDBOX/manifest"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.config/omakux-req/x.ini" ]
  [[ "$output" == *"0 renderizados, 1 omitidos"* ]]
}

@test "un target sin permisos se avisa y no aborta la aplicacion" {
  printf 'gdm/custom.css /proc/omakux-test/custom.css -\n' \
    >"$SANDBOX/manifest"
  export OMAKUX_MANIFEST="$SANDBOX/manifest"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [[ "$output" == *"sin permisos"* ]]
  [[ "$output" == *"aplicado"* ]]
  [ "$(cat "$OMAKUX_STATE/theme")" = "gruvbox-dark" ]
}

@test "un requisito root sin sudo se omite avisando" {
  printf 'gdm/custom.css /proc/omakux-test2/custom.css root\n' \
    >"$SANDBOX/manifest"
  export OMAKUX_MANIFEST="$SANDBOX/manifest"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]
  [[ "$output" == *"omitido"* ]]
  [[ "$output" == *"0 renderizados, 1 omitidos"* ]]
  [ ! -e /proc/omakux-test2/custom.css ]
}

@test "theme set fusiona el fragmento de vscode conservando tus claves" {
  mkdir -p "$HOME/.config/Code/User"
  printf '{"files.trimTrailingWhitespace": true}\n' >"$HOME/.config/Code/User/settings.json"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  local out="$HOME/.config/Code/User/settings.json"
  grep -q 'trimTrailingWhitespace' "$out"
  grep -q 'terminal.ansiRed' "$out"
  grep -q '"editor.colorTheme": "Gruvbox Dark Hard"' "$out"
  jq -e . "$out" >/dev/null
  [ -n "$(find "$OMAKUX_STATE/backup" -name 'settings.json' 2>/dev/null)" ]
}

@test "theme set fusiona settings de discord solo del selector claro/oscuro" {
  mkdir -p "$HOME/.config/discord"
  printf '{"backend": "http", "safeMode": true}\n' >"$HOME/.config/discord/settings.json"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-set" gruvbox-dark
  [ "$status" -eq 0 ]

  local out="$HOME/.config/discord/settings.json"
  grep -q '"theme": "dark"' "$out"
  grep -q '"backend": "http"' "$out"
  jq -e . "$out" >/dev/null
}

@test "theme lint valida un tema bueno y falla en uno roto" {
  run bash "$OMAKUX_ROOT/bin/omakux-theme-lint" gruvbox-dark
  [ "$status" -eq 0 ]
  [[ "$output" == *"paleta mínima completa"* ]]

  mkdir -p "$OMAKUX_ROOT/themes/_broken"
  printf '# roto\n# shellcheck disable=SC2034\ncolor_bg="naranja"\n' >"$OMAKUX_ROOT/themes/_broken/colors.sh"

  run bash "$OMAKUX_ROOT/bin/omakux-theme-lint" _broken
  [ "$status" -eq 1 ]
  [[ "$output" == *"colores obligatorios ausentes"* ]]
  [[ "$output" == *"no son #rrggbb"* ]]
}

@test "theme lint rechaza un esquema o acento de gnome desconocido" {
  mkdir -p "$OMAKUX_ROOT/themes/_broken"
  cat >"$OMAKUX_ROOT/themes/_broken/colors.sh" <<'EOF'
# roto
# shellcheck disable=SC2034
color_bg="#111111"
color_fg="#eeeeee"
color_surface="#222222"
color_accent="#333333"
color_muted="#444444"
color_red="#ff0000"
color_green="#00ff00"
color_yellow="#ffff00"
color_blue="#0000ff"
color_magenta="#ff00ff"
color_cyan="#00ffff"
color_orange="#ff8800"
gnome_scheme="tema-oscuro"
gnome_accent="azul"
EOF

  run bash "$OMAKUX_ROOT/bin/omakux-theme-lint" _broken
  [ "$status" -eq 1 ]
  [[ "$output" == *"gnome_scheme inválido"* ]]
  [[ "$output" == *"gnome_accent inválido"* ]]
}

@test "theme live re-aplica el tema cuando cambias colors.sh" {
  local dir="$OMAKUX_ROOT/themes/_live-test"
  mkdir -p "$dir"
  cp "$OMAKUX_ROOT/themes/tokyonight/colors.sh" "$dir/colors.sh"
  sed -i '1s/.*/# _live-test — tema temporal de pruebas/' "$dir/colors.sh"

  export OMAKUX_LIVE_INTERVAL="0.1"
  local log="$SANDBOX/live.log"
  bash "$OMAKUX_ROOT/bin/omakux-theme-live" _live-test >"$log" 2>&1 &
  live_pid=$!

  local i ok_first=0 ok_change=0
  for i in $(seq 1 60); do
    grep -q 're-aplicado' "$log" 2>/dev/null && { ok_first=1; break; }
    sleep 0.1
  done
  [ "$ok_first" -eq 1 ]

  sed -i 's/^color_bg=.*/color_bg="#112233"/' "$dir/colors.sh"

  for i in $(seq 1 60); do
    grep -q 'cambio detectado' "$log" 2>/dev/null && { ok_change=1; break; }
    sleep 0.1
  done
  [ "$ok_change" -eq 1 ]

  kill "$live_pid" 2>/dev/null || true
  wait "$live_pid" 2>/dev/null || true
  live_pid=""

  grep -q '#112233' "$HOME/.config/alacritty/alacritty.toml"
  [[ "$(cat "$OMAKUX_STATE/theme")" == "_live-test" ]]
}

@test "la ayuda lista theme lint y theme live en su seccion" {
  run bash "$OMAKUX_ROOT/bin/omakux" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"theme-lint"* ]]
  [[ "$output" == *"theme-live"* ]]
}
