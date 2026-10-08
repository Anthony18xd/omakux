#!/usr/bin/env bats
# Fase 4: agentes IA — AGENTS.md factory (scaffold) y estado (doctor)

load test_helper

setup() {
  setup_sandbox
  WORK="$SANDBOX/pro"
  mkdir -p "$WORK"
}

teardown() {
  teardown_sandbox
}

@test "agent scaffold escribe un AGENTS.md con tus convenciones" {
  run bash "$OMAKUX_ROOT/bin/omakux-agent-scaffold" "$WORK"
  [ "$status" -eq 0 ]
  [ -f "$WORK/AGENTS.md" ]
  grep -q '## Cómo trabajar aquí' "$WORK/AGENTS.md"
  grep -q 'omakux agent scaffold' "$WORK/AGENTS.md"
  grep -q "## Forma de trabajo omakux" "$WORK/AGENTS.md"
  grep -q '## Forma de trabajo omakux' "$WORK/AGENTS.md"
}

@test "agent scaffold detecta lint y tests de scripts/" {
  mkdir -p "$WORK/scripts" "$WORK/tests"
  : >"$WORK/scripts/lint.sh"
  : >"$WORK/scripts/test.sh"
  run bash "$OMAKUX_ROOT/bin/omakux-agent-scaffold" "$WORK"
  [ "$status" -eq 0 ]
  grep -q 'scripts/lint.sh' "$WORK/AGENTS.md"
  grep -q 'scripts/test.sh' "$WORK/AGENTS.md"
}

@test "agent scaffold detecta lint y tests de package.json" {
  printf '{ "scripts": { "lint": "eslint", "test": "vitest" } }\n' >"$WORK/package.json"
  run bash "$OMAKUX_ROOT/bin/omakux-agent-scaffold" "$WORK"
  [ "$status" -eq 0 ]
  grep -q 'npm run lint' "$WORK/AGENTS.md"
  grep -q 'npm test' "$WORK/AGENTS.md"
}

@test "agent scaffold respalda un AGENTS.md existente y no lo pisa sin aviso" {
  git="$OMAKUX_STATE/backup"
  mkdir -p "$git"
  printf 'mis reglas previas\n' >"$WORK/AGENTS.md"
  run bash "$OMAKUX_ROOT/bin/omakux-agent-scaffold" "$WORK"
  [ "$status" -eq 0 ]
  grep -q 'respaldado' <<<"$output"

  backup="$(find "$git" -name 'AGENTS.md*' -type f 2>/dev/null | head -1)"
  [ -n "$backup" ]
  grep -q 'mis reglas previas' "$backup"
  grep -q '## Cómo trabajar aquí' "$WORK/AGENTS.md"
}

@test "agent scaffold falla si el directorio no existe" {
  run bash "$OMAKUX_ROOT/bin/omakux-agent-scaffold" "$SANDBOX/no-existe"
  [ "$status" -ne 0 ]
}

@test "agent doctor reporta el estado de cada agente" {
  cat >"$OMAKUX_BIN_STUBS/claude" <<'EOF'
#!/usr/bin/env bash
echo "Claude Code 9.9.9"
EOF
  chmod +x "$OMAKUX_BIN_STUBS/claude"

  run bash "$OMAKUX_ROOT/bin/omakux-agent-doctor"
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude"*"listo"* ]]
  [[ "$output" == *"codex"* ]]
  [[ "$output" == *"no instalado"* ]]
  [[ "$output" == *"agentes IA:"* ]]
}

@test "agent doctor informa de los runtimes" {
  run bash "$OMAKUX_ROOT/bin/omakux-agent-doctor"
  [ "$status" -eq 0 ]
  [[ "$output" == *"runtimes:"* ]]
  [[ "$output" == *"ffmpeg"* ]]
}

@test "agent scaffold y doctor aparecen en la ayuda de omakux" {
  run bash "$OMAKUX_ROOT/bin/omakux" --commands
  [ "$status" -eq 0 ]
  [[ "$output" == *"agent scaffold"* ]]
  [[ "$output" == *"agent doctor"* ]]
  run bash "$OMAKUX_ROOT/bin/omakux" help agent scaffold
  [ "$status" -eq 0 ]
  [[ "$output" == *"Genera un AGENTS.md"* ]]
}