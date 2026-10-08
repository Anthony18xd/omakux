#!/usr/bin/env bats
# el orquestador de fases: --only, --skip, --dry-run y validación de fases

load test_helper

setup() {
  setup_sandbox
  run_install() {
    run env OMAKUX_PATH="$OMAKUX_ROOT" OMAKUX_STATE="$OMAKUX_STATE" OMAKUX_DRY=1 \
      bash "$OMAKUX_ROOT/install.sh" "$@"
  }
}

teardown() {
  teardown_sandbox
}

@test "--dry-run --only check sale 0 y no crea sellos de fase" {
  run_install --dry-run --only check
  [ "$status" -eq 0 ]
  [[ "$output" == *"fase: check"* ]]
  [[ "$output" == *"MODE DRY-RUN"* || "$output" == *"MODO DRY-RUN"* ]]
  [ ! -e "$OMAKUX_STATE/phase-check.done" ]
}

@test "dos dry-runs seguidos repiten la fase (no se sella nada)" {
  run_install --dry-run --only check
  [ "$status" -eq 0 ]
  run_install --dry-run --only check
  [ "$status" -eq 0 ]
  [[ "$output" == *"fase: check"* ]]
}

@test "--only con fase inexistente es un error, no una ejecución vacía" {
  run_install --only fase-que-no-existe
  [ "$status" -eq 1 ]
  [[ "$output" == *"fase desconocida"* ]]
}

@test "--skip con fase inexistente también es un error" {
  run_install --skip fase-que-no-existe
  [ "$status" -eq 1 ]
  [[ "$output" == *"fase desconocida"* ]]
}

@test "ayuda del instalador lista las fases válidas" {
  run env OMAKUX_PATH="$OMAKUX_ROOT" bash "$OMAKUX_ROOT/install.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"fases: check packages identification"* ]]
  [[ "$output" == *"--dry-run"* ]]
}

@test "el instalador no se puede ejecutar con fase marcada y sin --force" {
  # simula una fase ya completada
  date '+%F %T' >"$OMAKUX_STATE/phase-check.done"
  run_install --only check
  [ "$status" -eq 0 ]
  [[ "$output" == *"ya completada"* ]]
  # --force la repite
  run_install --only check --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"fase: check"* ]]
}
