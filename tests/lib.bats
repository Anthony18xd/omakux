#!/usr/bin/env bats
# lib.sh: seed/backup, modo dry-run y sello de fases

load test_helper

setup() {
  setup_sandbox
  # wrapper para correr un trozo de lib.sh con el sandbox activo
  run_lib() {
    run env OMAKUX_PATH="$OMAKUX_ROOT" OMAKUX_STATE="$OMAKUX_STATE" \
      OMAKUX_DRY="${OMAKUX_DRY:-0}" bash -c "
      set -euo pipefail
      source \"\$OMAKUX_PATH/install/lib.sh\"
      $1
    "
  }
}

teardown() {
  teardown_sandbox
}

@test "seed copia el archivo cuando no existe en destino" {
  run_lib 'seed "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"'
  [ "$status" -eq 0 ]
  cmp -s "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"
}

@test "seed respalda el original si el destino es distinto" {
  mkdir -p "$HOME/.config"
  echo "mi config propia" >"$HOME/.config/omakux-version"
  run_lib 'seed "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"'
  [ "$status" -eq 0 ]
  # el contenido original quedó guardado en el estado
  grep -q "mi config propia" "$OMAKUX_STATE/backup/$HOME/.config/omakux-version"
  # y el destino ahora es el del repo
  cmp -s "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"
}

@test "seed no hace backup si el destino ya es idéntico" {
  mkdir -p "$HOME/.config"
  cp "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"
  run_lib 'seed "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"'
  [ "$status" -eq 0 ]
  [ ! -e "$OMAKUX_STATE/backup/$HOME/.config/omakux-version" ]
}

@test "seed solo copia si falta (seed_once)" {
  mkdir -p "$HOME/.config"
  echo "mio" >"$HOME/.config/omakux-version"
  run_lib 'seed_once "$OMAKUX_PATH/version" "$HOME/.config/omakux-version"'
  [ "$status" -eq 0 ]
  grep -q "^mio$" "$HOME/.config/omakux-version"
}

@test "en dry-run, run() no ejecuta nada y lo anuncia" {
  export OMAKUX_DRY=1
  run_lib 'run touch "$HOME/no-debe-existir"; echo fin'
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY touch"* ]]
  [[ "$output" == *"fin"* ]]
  [ ! -e "$HOME/no-debe-existir" ]
}

@test "en dry-run, no se crean sellos de fase" {
  export OMAKUX_DRY=1
  run_lib 'state_mark phase-test'
  [ "$status" -eq 0 ]
  [ ! -e "$OMAKUX_STATE/phase-test.done" ]
}

@test "sin dry-run, state_mark crea el sello y state_done lo detecta" {
  run_lib 'state_mark phase-test; state_done phase-test && echo SI'
  [ "$status" -eq 0 ]
  [[ "$output" == *"SI"* ]]
  [ -e "$OMAKUX_STATE/phase-test.done" ]
}

@test "apt_install en dry-run no registra paquetes" {
  export OMAKUX_DRY=1
  run_lib 'apt_install paquete-que-no-existe-omakux'
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY apt install paquete-que-no-existe-omakux"* ]]
  [ ! -e "$OMAKUX_STATE/installed-packages.txt" ]
}

@test "backup_file no duplica si el contenido es el mismo" {
  mkdir -p "$HOME/.config"
  echo "hola" >"$HOME/.config/archivo"
  run_lib 'backup_file "$HOME/.config/archivo"; backup_file "$HOME/.config/archivo"'
  [ "$status" -eq 0 ]
  local bak="$OMAKUX_STATE/backup/$HOME/.config/archivo"
  [ -f "$bak" ]
  # solo un backup: el segundo cksum coincide y se salta
  [ "$(find "$OMAKUX_STATE/backup" -name 'archivo*' | wc -l)" -eq 1 ]
}
