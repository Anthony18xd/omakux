#!/usr/bin/env bash
# omakux:summary Install the full Hyprland session (Omarchy-style)
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo
apt_install_list "$OMAKUX_PATH/install/packages/hyprland.apt"

log "sembrando configuración de Hyprland"

# --- configs semilla (los templates temáticos se regeneran en la fase theme) ---
seed "$OMAKUX_PATH/config-themes/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
seed "$OMAKUX_PATH/config-themes/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
seed "$OMAKUX_PATH/config-themes/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
seed "$OMAKUX_PATH/config-themes/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
seed "$OMAKUX_PATH/config-themes/waybar/style.css" "$HOME/.config/waybar/style.css"
seed "$OMAKUX_PATH/config-themes/wofi/config" "$HOME/.config/wofi/config"
seed "$OMAKUX_PATH/config-themes/wofi/style.css" "$HOME/.config/wofi/style.css"
seed "$OMAKUX_PATH/config-themes/dunst/dunst.conf" "$HOME/.config/dunst/dunst.conf"

seed_once "$OMAKUX_PATH/config-themes/hypr/local.conf" "$HOME/.config/hypr/local.conf"

mkdir -p "$HOME/.config/hypr/scripts"
for s in "$OMAKUX_PATH"/config-themes/hypr/scripts/*.sh; do
  [ -f "$s" ] || continue
  seed "$s" "$HOME/.config/hypr/scripts/$(basename "$s")"
done
if [ "$OMAKUX_DRY" != "1" ]; then
  chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
fi

# --- gpu.conf: AMD iGPU como primaria, NVIDIA secundaria (offload) ---
gpu_conf="$HOME/.config/hypr/gpu.conf"
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY generar gpu.conf + input.conf"
else
  if lspci 2>/dev/null | grep -qi 'VGA compatible controller'; then
    amd_path=""
    nvidia_path=""
    while read -r addr desc; do
      if echo "$desc" | grep -qiE 'AMD|Advanced Micro'; then
        if [ -z "$amd_path" ]; then amd_path="/dev/dri/by-path/pci-$addr-card"; fi
      elif echo "$desc" | grep -qi NVIDIA; then
        if [ -z "$nvidia_path" ]; then nvidia_path="/dev/dri/by-path/pci-$addr-card"; fi
      fi
    done < <(lspci -D | awk '/VGA compatible controller/ {addr=$1; sub($1 FS, ""); print addr, $0}')

    {
      echo "# generado por omakux: GPU híbrida — AMD iGPU primaria, NVIDIA para offload (prime-run)"
      if [ -n "$amd_path" ] && [ -e "$amd_path" ]; then
        if [ -n "$nvidia_path" ] && [ -e "$nvidia_path" ]; then
          echo "env = AQ_DRM_DEVICES,$amd_path:$nvidia_path"
        else
          echo "env = AQ_DRM_DEVICES,$amd_path"
        fi
      fi
      if [ -n "$nvidia_path" ]; then
        echo "# NVIDIA offload: prime-run <app>  (paquete nvidia-prime)"
      fi
    } >"$gpu_conf"
    ok "gpu.conf: amd=${amd_path:-no} nvidia=${nvidia_path:-no}"
  fi

  # --- input.conf: layout de teclado heredado de GNOME ---
  layout="$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null |
    sed -nE "s/.*'xkb', '([a-z0-9]+)'.*/\1/p")" || true
  layout="${layout:-us}"
  {
    echo "# generado por omakux: heredado de GNOME ($layout)"
    echo "input {"
    echo "    kb_layout = $layout"
    echo "    kb_options = "
    echo "    follow_mouse = 1"
    echo "    sensitivity = 0"
    echo "    accel_profile = "
    echo "    touchpad {"
    echo "        natural_scroll = true"
    echo "        tap-to-click = true"
    echo "        disable_while_typing = true"
    echo "    }"
    echo "}"
  } >"$HOME/.config/hypr/input.conf"
  ok "input.conf: kb_layout=$layout"
fi

# --- portales para la sesión Hyprland (no afecta a GNOME) ---
mkdir -p "$HOME/.config/xdg-desktop-portal"
if [ "$OMAKUX_DRY" != "1" ]; then
  cat >"$HOME/.config/xdg-desktop-portal/Hyprland-portals.conf" <<'EOF'
[preferred]
default=gtk
org.freedesktop.impl.Monitor=hyprland
org.freedesktop.impl.Screencast=hyprland
org.freedesktop.impl.FileChooser=gtk
EOF
fi

# --- sesión de GDM ---
session=/usr/share/wayland-sessions/hyprland.desktop
if [ -f "$session" ]; then
  ok "sesión Hyprland disponible en GDM"
else
  warn "no aparece el archivo de sesión $session — revisa 'dpkg -L hyprland'"
fi

# si ya hay tema activo, re-renderiza las configs recién sembradas
if [ -f "$OMAKUX_STATE/theme" ] && [ "$OMAKUX_DRY" != "1" ]; then
  "$OMAKUX_PATH/bin/omakux-theme-set" "$(cat "$OMAKUX_STATE/theme")" >/dev/null 2>&1 || true
fi

ok "sesión Hyprland instalada (cierra sesión y elige 'Hyprland' en GDM)"
