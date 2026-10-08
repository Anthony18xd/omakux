#!/usr/bin/env bats
# el lint no debe depender del directorio desde el que se lance

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "scripts/lint.sh sale 0 desde cualquier directorio" {
  # regresión: sin cd a la raíz del repo, shellcheck no resolvía los
  # `source install/lib.sh` y soltaba 11 SC2154 falsos
  local dir
  for dir in / /tmp "$HOME"; do
    run bash -c "cd '$dir' && exec bash '$OMAKUX_ROOT/scripts/lint.sh'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok: sin avisos"* ]]
  done
}

@test "omakux lint existe como comando" {
  run_omakux lint
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok: sin avisos"* ]]
}
