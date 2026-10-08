#!/usr/bin/env bats
# Fase 2: fichas de comando, sugerencias de typos y completions

load test_helper

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "omakux --commands lista los comandos en forma natural" {
  run bash "$OMAKUX_ROOT/bin/omakux" --commands
  [ "$status" -eq 0 ]
  [[ "$output" == *"theme set"* ]]
  [[ "$output" == *"pkg install"* ]]
  [[ "$output" == *"webapp add"* ]]
  # el nombre en crudo no debe aparecer (se imprime en forma de tokens)
  ! grep -q 'theme-set' <<<"$output"
}

@test "omakux help <comando> muestra la ficha completa" {
  run bash "$OMAKUX_ROOT/bin/omakux" help theme set
  [ "$status" -eq 0 ]
  [[ "$output" == *"omakux theme set"* ]]
  [[ "$output" == *"Apply a theme everywhere"* ]]
  [[ "$output" == *"grupo:  theme"* ]]
  [[ "$output" == *"ficha:"* ]]
  [[ "$output" == *"del mismo grupo"* ]]
}

@test "omakux <comando> --help es la misma ficha" {
  run bash "$OMAKUX_ROOT/bin/omakux" theme set --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"uso: omakux theme set <nombre>"* ]]
  [[ "$output" == *"del mismo grupo"* ]]
}

@test "omakux help de un comando de una sola palabra" {
  run bash "$OMAKUX_ROOT/bin/omakux" doctor --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Health check"* ]]
  [[ "$output" == *"grupo:  system"* ]]
}

@test "omakux help de un comando inexistente falla con sugerencias" {
  run bash "$OMAKUX_ROOT/bin/omakux" help no-existe
  [ "$status" -eq 1 ]
  [[ "$output" == *"no existe el comando"* ]]
}

@test "un typo en el comando sugiere los parecidos por stderr" {
  run bash "$OMAKUX_ROOT/bin/omakux" teme set
  [ "$status" -eq 1 ]
  [[ "$output" == *"comando desconocido: teme set"* ]]
  [[ "$output" == *"omakux theme set"* ]]
  [[ "$output" == *"Ejecuta 'omakux'"* ]]
}

@test "un subcomando malo sugiere los hermanos de ese grupo" {
  run bash "$OMAKUX_ROOT/bin/omakux" theme zzz
  [ "$status" -eq 1 ]
  [[ "$output" == *"omakux theme list"* ]]
  [[ "$output" == *"omakux theme set"* ]]
}

@test "completion bash genera un script que bash entiende" {
  run bash "$OMAKUX_ROOT/bin/omakux-completion" bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _omakux omakux"* ]]
  [[ "$output" == *"theme) subs="* ]]
  printf '%s\n' "$output" >"$SANDBOX/omakux.bash"
  run bash -n "$SANDBOX/omakux.bash"
  [ "$status" -eq 0 ]
}

@test "completion fish genera un script que fish entiende" {
  command -v fish >/dev/null 2>&1 || skip "fish no instalado"
  run bash "$OMAKUX_ROOT/bin/omakux-completion" fish
  [ "$status" -eq 0 ]
  [[ "$output" == *"__fish_seen_subcommand_from theme"* ]]
  [[ "$output" == *"install bash fish zsh"* ]]
  printf '%s\n' "$output" >"$SANDBOX/omakux.fish"
  run fish --no-execute "$SANDBOX/omakux.fish"
  [ "$status" -eq 0 ]
}

@test "completion install la deja en el sitio de tu shell" {
  SHELL=/usr/bin/fish
  export SHELL
  run bash "$OMAKUX_ROOT/bin/omakux-completion" install
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/fish/completions/omakux.fish" ]
  grep -q '__fish_seen_subcommand_from theme' "$HOME/.config/fish/completions/omakux.fish"
}

@test "completion install en dry-run no escribe nada" {
  export OMAKUX_DRY=1
  run bash "$OMAKUX_ROOT/bin/omakux-completion" install fish
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY completion"* ]]
  [ ! -e "$HOME/.config/fish/completions/omakux.fish" ]
}

@test "el comando completion expone summary y group (help depende de ello)" {
  run bash "$OMAKUX_ROOT/bin/omakux-completion" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"uso: omakux completion"* ]]
}
