# Sesión Hyprland

Se elige en GDM al iniciar sesión (junto a GNOME).

## Atajos

| Tecla | Acción |
|---|---|
| `Super+Enter` | terminal (Alacritty) |
| `Super+Espacio` | lanzador de apps (wofi) |
| `Super+Mayús+Espacio` | menú omakux |
| `Super+E` | explorador (Nautilus) |
| `Super+B` | navegador (Chromium) |
| `Super+Q` | cerrar ventana |
| `Super+F` | pantalla completa |
| `Super+T` | flotar/on |
| `Super+L` | bloquear (hyprlock) |
| `Super+V` | historial del portapapeles |
| `Super+Mayús+Q` | menú de energía |
| `Super+h/j/k/l` | mover foco |
| `Super+Mayús+h/j/k/l` | mover ventana |
| `Super+Ctrl+h/j/k/l` | redimensionar |
| `Super+1..9` | espacio de trabajo |
| `Super+Mayús+1..9` | mover a espacio |
| `Super+G` | agrupar ventanas |
| `Print` | captura de área |
| `Mayús+Print` | captura completa |
| `Super+Mayús+S` | captura de área |
| `Super+Mayús+R` | grabar pantalla (toggle) |
| `Super+Mayús+E` | salir de la sesión |
| Volumen/brillo (multimedia) | OSD con notificaciones |

## Personaliza

- **Tus binds/config extra**: `~/.config/hypr/local.conf` (se carga al final).
- **Monitores**: `~/.config/hypr/monitors.conf` si lo creas, o edita `monitor =` en hyprland.conf (respaldado en update).
- **Wallpaper**: cambia el tema (`omakux theme set X`) o pon el tuyo en `~/.local/state/omakux/wallpapers/active.png`.

## GPU híbrida (NVIDIA + AMD)

`~/.config/hypr/gpu.conf` fuerza la iGPU AMD como principal (fluida) y deja NVIDIA
disponible para offload:

```bash
prime-run vlc        # app concreta en la NVIDIA
prime-run steam
```

Si la pantalla exterior no se detecta: `hyprctl monitors` y revisa `gpu.conf`.

## Problemas conocidos

- **Screen share en Wayland**: los portales de Hyprland están en
  `~/.config/xdg-desktop-portal/Hyprland-portals.conf`. En Chrome/Chromium
  usa la pestaña Share → "Entire screen".
- **Apps Electron sin Wayland**: ya está `ELECTRON_OZONE_PLATFORM_HINT=wayland`.
- **Se ve raro al cambiar de sesión**: reinicia la sesión; GNOME y Hyprland
  comparten `~/.config` de apps (alacritty, etc.) sin conflicto.
