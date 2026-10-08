#!/usr/bin/env bash
# helpers comunes para la suite de bats

OMAKUX_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# sandbox aislado: HOME, estado y binarios propios.
# nada de lo que pase aquí toca la instalación real.
setup_sandbox() {
  SANDBOX="$(mktemp -d)"
  export HOME="$SANDBOX/home"
  export OMAKUX_STATE="$SANDBOX/state"
  export OMAKUX_BIN_STUBS="$SANDBOX/bin"
  mkdir -p "$HOME" "$OMAKUX_STATE" "$OMAKUX_BIN_STUBS"

  # la sesión de hyprland no debe interferir (los tests corren en GNOME o CI)
  unset HYPRLAND_INSTANCE_SIGNATURE

  export PATH="$OMAKUX_BIN_STUBS:$PATH"

  # gsettings: registra las llamadas en vez de tocar la sesión real
  cat >"$OMAKUX_BIN_STUBS/gsettings" <<'EOF'
#!/usr/bin/env bash
printf 'gsettings %s\n' "$*" >>"${STUB_LOG:-/dev/null}"
EOF

  # notify-send: silencioso
  cat >"$OMAKUX_BIN_STUBS/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  # convert/magick: "rasteriza" creando el destino vacío (sin CPU)
  cat >"$OMAKUX_BIN_STUBS/magick" <<'EOF'
#!/usr/bin/env bash
for last; do :; done
: >"$last"
EOF
  cp "$OMAKUX_BIN_STUBS/magick" "$OMAKUX_BIN_STUBS/convert"

  # curl: siempre éxito (sin red en los tests)
  cat >"$OMAKUX_BIN_STUBS/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  chmod +x "$OMAKUX_BIN_STUBS"/*
  export STUB_LOG="$SANDBOX/stubs.log"
  : >"$STUB_LOG"

  export OMAKUX_PATH="$OMAKUX_ROOT"
}

teardown_sandbox() {
  [ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"
}

# copia el router + los comandos a un dir propio y lo exporta como OMAKUX_CLI
setup_fake_cli() {
  OMAKUX_CLI="$SANDBOX/cli"
  mkdir -p "$OMAKUX_CLI"
  cp "$OMAKUX_ROOT/bin/"omakux* "$OMAKUX_CLI/"
}

run_omakux() {
  run bash "$OMAKUX_ROOT/bin/omakux" "$@"
}
