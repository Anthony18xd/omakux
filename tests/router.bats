#!/usr/bin/env bats
# el router: ayuda, despacho por prefijo y errores

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "sin argumentos imprime la ayuda y sale 0" {
  run_omakux
  [ "$status" -eq 0 ]
  [[ "$output" == *"usage: omakux <command> [args]"* ]]
  [[ "$output" == *"docs:"* ]]
}

@test "la ayuda agrupa los comandos por sección" {
  run_omakux
  [ "$status" -eq 0 ]
  [[ "$output" == *"THEME"* ]]
  [[ "$output" == *"PKG"* ]]
  [[ "$output" == *"theme-set"* ]]
  [[ "$output" == *"pkg-install"* ]]
}

@test "cada comando de la ayuda lleva descripción" {
  # ninguna línea de comando debe quedar sin texto tras el nombre
  run_omakux
  [ "$status" -eq 0 ]
  ! grep -E '^  [a-z-]+[[:space:]]*$' <<<"$output"
}

@test "--version imprime la versión del repo" {
  run_omakux --version
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$OMAKUX_ROOT/version")" ]
}

@test "comando inexistente falla con mensaje útil" {
  run_omakux frobnicate
  [ "$status" -eq 1 ]
  [[ "$output" == *"comando desconocido"* ]]
  [[ "$output" == *"Ejecuta 'omakux'"* ]]
}

@test "despacha 'theme list' al comando theme-list" {
  run_omakux theme list
  [ "$status" -eq 0 ]
  [[ "$output" == *"aplicar: omakux theme set"* ]]
}

@test "prefijo más largo gana: foo-bar se resuelve antes que foo" {
  setup_fake_cli
  cat >"$OMAKUX_CLI/omakux-foo" <<'EOF'
#!/usr/bin/env bash
echo "foo:$*" >>"$CALLS"
EOF
  cat >"$OMAKUX_CLI/omakux-foo-bar" <<'EOF'
#!/usr/bin/env bash
echo "foo-bar:$*" >>"$CALLS"
EOF
  chmod +x "$OMAKUX_CLI"/omakux-foo*
  export CALLS="$SANDBOX/calls.log"
  : >"$CALLS"

  run bash "$OMAKUX_CLI/omakux" foo bar baz
  [ "$status" -eq 0 ]
  grep -q '^foo-bar:baz$' "$CALLS"
  ! grep -q '^foo:' "$CALLS"
}

@test "sin match, el error sale por stderr" {
  run_omakux no nope
  [ "$status" -eq 1 ]
  [ "${lines[0]:-}" = "omakux: comando desconocido: no nope" ]
}

@test "todos los comandos exponen summary y group (el help depende de ellos)" {
  local f
  for f in "$OMAKUX_ROOT/bin/"omakux-*; do
    grep -q '^# omakux:summary' "$f"
    grep -q '^# omakux:group' "$f"
  done
}
