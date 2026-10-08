# omakux

Tu Ubuntu convertido en un workstation de desarrollo completo y bonito — con **una sola línea**.

Inspirado en [Omarchy](https://omarchy.org) (DHH) y [Omakub](https://github.com/basecamp/omakub), pero para Ubuntu: mantiene **GNOME como escritorio principal** y añade una **sesión Hyprland completa** (estilo Omarchy) que eliges en el login.

```
┌──────────────────────────────────────────────────────┐
│  · GNOME 50 (default) + Hyprland (selector de GDM)  │
│  · 3 temas que pintan TODO (GNOME, terminal, barra)  │
│  · fish + starship + LazyVim + mise + docker         │
│  · timeshift snapshots + ufw + autoupdates           │
│  · CLI unificado: omakux <comando>                   │
│  · IA: Claude Code, Codex, Ollama, voxtype           │
└──────────────────────────────────────────────────────┘
```

## Instalar

```bash
# desde este repo (desarrollo)
bash install.sh

# o remoto (cuando publiques el repo)
curl -fsSL https://raw.githubusercontent.com/<tu-usuario>/omakux/main/boot.sh | bash
```

Requisitos: **Ubuntu 24.04+**, x86_64/aarch64, ~10 GB libres, internet, sudo.

Opciones:

```bash
bash install.sh --dry-run          # ver qué haría sin tocar nada
bash install.sh --only hyprland    # una fase concreta
bash install.sh --skip ai          # saltar fases
bash install.sh --force            # repetir fases ya completadas
```

Fases: `check packages identification terminal gnome apps system hyprland theme ai finalize`

## Después de instalar

1. **Cierra sesión** → en GDM elige **GNOME** (default) o **Hyprland**.
2. En Hyprland: `Super+Espacio` lanza apps, `Super+Mayús+Espacio` el menú omakux.
3. En GNOME: `Super+Enter` abre Alacritty, `omakux menu` abre el menú.

## La CLI

| Comando | Qué hace |
|---|---|
| `omakux` | lista todos los comandos |
| `omakux update` | snapshot + apt + flatpak + snap + git + reaplica configs |
| `omakux doctor` | diagnóstico de la instalación |
| `omakux menu` | menú interactivo (wofi/gum) |
| `omakux theme set/list/install` | cambiar temas en todo el sistema |
| `omakux webapp add <nombre> <url>` | convierte un sitio en app con icono |
| `omakux pkg install <pkg>` | apt con registro para desinstalar después |
| `omakux capture [area\|full]` | capturas en GNOME **y** Hyprland |
| `omakux snapshot create/list/delete` | snapshots de sistema (timeshift) |
| `omakux ai install <claude\|codex\|ollama\|voxtype>` | agentes de IA |
| `omakux config reset` | reaplica configs del repo (respalda tus edits) |
| `omakux uninstall` | desinstala y restaura lo original |

## Temas

Un solo `colors.sh` + `wallpaper.svg` por tema pinta: GNOME (gsettings/fondo), Alacritty, Waybar, Wofi, Hyprlock, Dunst, tmux, Starship, btop, Neovim y VSCode.

```
omakux theme list
omakux theme set gruvbox-dark
omakux theme install https://github.com/usuario/omakux-mi-tema-theme
```

Semilla: `tokyonight` (default), `catppuccin-mocha`, `gruvbox-dark`.

### Crear un tema

Copia `themes/tokyonight/`, cambia colores en `colors.sh` (mínimos: `color_bg fg surface accent muted red green yellow blue magenta cyan orange`), edita `wallpaper.svg` y haz `omakux theme set <nombre>`.

## Estructura

```
omakux/
├── boot.sh              # entrypoint remoto
├── install.sh           # orquestador de fases (dry-run, --only, --force)
├── bin/                 # CLI: router + omakux-<comando> (headers # omakux:summary)
├── install/             # fases + listas de paquetes *.apt
├── config/              # semillas estáticas (fish, tmux, yazi)
├── config-themes/       # templates con {{placeholders}} (se renderizan por tema)
├── themes/              # <tema>/colors.sh + wallpaper.svg
├── applications/        # install/ y remove/ de apps opcionales
├── migrations/          # cambios entre versiones
├── scripts/             # lint.sh y test.sh (lo que corre la CI)
├── tests/               # suite bats: router, temas, lib.sh, instalador
└── uninstall/           # desinstalador
```

## Desarrollo

```bash
omakux lint   # shellcheck sobre los 56 scripts
omakux test   # lint + 34 tests bats
```

(atajos: `scripts/lint.sh` y `scripts/test.sh`, lo mismo que corre la CI)

Los tests corren en un **sandbox** (`HOME`, `OMAKUX_STATE` y `PATH` propios, con
`gsettings`/`curl`/`magick` reemplazados por stubs): no tocan tu sesión real,
tu ni tu instalación. La CI ejecuta lo mismo en un contenedor Ubuntu limpio.

Reglas que la CI hace cumplir:

- **shellcheck limpio** en todo el bash del repo (`.shellcheckrc`).
- El **router** resuelve prefijos (`theme set` → `omakux-theme-set`), y todo
  comando expone `# omakux:summary` y `# omakux:group` (si no, el help se rompe).
- **Nada se escribe en dry-run**: ni sellos de fase, ni configs, ni estado.
- `seed`/`backup_file` respaldan antes de sobreescribir.
- Toda paleta define la lista mínima de colores.

## Seguridad

omakux **no** instala `NOPASSWD` en sudoers: cada comando que necesita root
llama a `sudo -v` una vez y la credencial se cachea unos minutos. Si prefieres
modo desatendido (y asumes que cualquier proceso de tu usuario será root),
está el modelo en `install/omakux-nopasswd.example` — instálalo a sabiendas:

```bash
sudo install -m 0440 install/omakux-nopasswd.example /etc/sudoers.d/omakux-nopasswd
sudo visudo -c
```


## Personalización sin romper updates

- **Hyprland**: tus binds extra → `~/.config/hypr/local.conf` (se carga al final, nunca se sobreescribe).
- **Configs semilla**: edítalas, `omakux update` las respalda antes de tocar.
- **Temas**: nunca edites los archivos renderizados (`style.css`, `alacritty.toml`…), se regeneran.

## Desinstalar

```bash
omakux uninstall
```

Restaura tus configs originales (backup en `~/.local/state/omakux/backup`), quita paquetes/snaps/flatpaks que instaló omakux y tu shell original. No borra los snapshots de timeshift.

## Docs

- [docs/BACKUPS.md](docs/BACKUPS.md) — snapshots y restauración
- [docs/HYPRLAND.md](docs/HYPRLAND.md) — atajos y trucos de la sesión
- [docs/SECURITY.md](docs/SECURITY.md) — sudo, backups y qué toca omakux
