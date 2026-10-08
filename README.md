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
| `omakux help <comando>` | ficha de un comando (uso, grupo, hermanos) |
| `omakux completion [install]` | completado para bash, fish o zsh |
| `omakux config list/diff` | qué dotfiles gestiona omakux y tus cambios sobre el repo |
| `omakux config export/import` | tus dotfiles a un repo (o desde uno) |
| `omakux agent scaffold` | AGENTS.md con tus convenciones para cada proyecto |
| `omakux agent doctor` | qué agentes IA y runtimes tienes listos |
| `omakux update` | snapshot + apt + flatpak + snap + git + reaplica configs |
| `omakux doctor` | diagnóstico de la instalación |
| `omakux menu` | menú interactivo (wofi/gum) |
| `omakux theme set/list/install` | cambiar temas en todo el sistema |
| `omakux theme lint/live` | validar una paleta / re-aplicar mientras editas |
| `omakux webapp add <nombre> <url>` | convierte un sitio en app con icono |
| `omakux pkg install <pkg>` | apt con registro para desinstalar después |
| `omakux capture [area\|full]` | capturas en GNOME **y** Hyprland |
| `omakux snapshot create/list/delete` | snapshots de sistema (timeshift) |
| `omakux ai install <claude\|codex\|ollama\|voxtype>` | agentes de IA |
| `omakux config reset` | reaplica configs del repo (respalda tus edits) |
| `omakux uninstall` | desinstala y restaura lo original |

## Tus dotfiles como producto

`config/dotfiles` lista todo lo que omakux gestiona (semillas `seed` que no se
tocan y configs `render` que genera el tema). Desde ahí:

```bash
omakux config list              # estado de cada dotfile (igual / modificada / falta)
omakux config diff              # tus cambios frente al repo (para decidir antes de un update)
omakux config export ~/dotfiles # versiona tus dotfiles en un repo git (con README y manifiesto)
omakux config import ~/dotfiles # restaura los de otra máquina (con backup previo)
```

Para los `render`, omakux guarda una foto de lo último que pintó
(`~/.local/state/omakux/rendered`): así `config diff` te muestra SOLO lo que
editaste después del `omakux theme set`, no el render entero.

## Agentes IA

omakux integra los agentes de código con tu estación, no a la inversa:

```bash
omakux ai install          # claude, codex, ollama (y voxtype para dictado)
omakux agent doctor        # estado de opencode, claude, codex, ollama y runtimes
omakux agent scaffold      # AGENTS.md con tus convenciones (fshell, lint/test detectados)
```

`omakux agent scaffold` detecta por ti el linter y la suite de tests del
proyecto (scripts/, package.json, Makefile, Cargo.toml…) y escribe un
AGENTS.md listo para cualquier agente (respaldando el tuyo si ya existía).

## Temas

Un solo `colors.sh` + `wallpaper.svg` por tema pinta **todo**: GNOME
(gsettings, iconos, cursor, acento, fondo), **GTK 3/4**, **GDM**, Alacritty,
Waybar, Wofi, Hyprlock, Dunst, tmux, Starship, btop, Neovim, VSCode y Discord.

Qué se pinta se decide en **`config-themes/manifest`** (declarativo: origen,
destino y requisito). Si la app no está instalada, esa línea se omite sin
ruido; los targets de sistema (`/etc/gdm3/custom.css`) piden sudo y, si no lo
tienes, se avisan y se omiten sin abortar.

```
omakux theme list
omakux theme set gruvbox-dark       # aplica el tema en todo
omakux theme lint gruvbox-dark      # valida la paleta sin aplicar nada
omakux theme live gruvbox-dark      # re-aplica solo mientras editas colors.sh
omakux theme install https://github.com/usuario/omakux-mi-tema-theme
```

Semilla: `tokyonight` (default), `catppuccin-mocha`, `gruvbox-dark`.

### Crear un tema

1. `cp -r themes/tokyonight themes/mi-tema`
2. Cambia los colores en `colors.sh` (mínimos: `color_bg fg surface accent
   muted red green yellow blue magenta cyan orange`; opcionales: `gtk_theme`,
   `icon_theme`, `cursor_theme`, `ui_font`, `gnome_accent`, `gnome_scheme`,
   `vscode_theme`, `nvim_plugin`/`nvim_theme`).
3. Edita `wallpaper.svg`.
4. `omakux theme lint mi-tema` → debe salir limpio.
5. `omakux theme set mi-tema`.

Para añadir una app nueva al motor: mete su template en `config-themes/<app>/`
con `{{placeholders}}` y una línea en `config-themes/manifest`. No toques nunca
los ficheros renderizados en `~/.config` (se regeneran).

## Estructura

```
omakux/
├── boot.sh              # entrypoint remoto
├── install.sh           # orquestador de fases (dry-run, --only, --force)
├── bin/                 # CLI: router + omakux-<comando> (headers # omakux:summary)
├── install/             # fases + listas de paquetes *.apt
├── config/              # semillas estáticas + config/dotfiles (manifiesto)
├── config-themes/       # manifest + templates con {{placeholders}}
├── themes/              # <tema>/colors.sh + wallpaper.svg
├── applications/        # install/ y remove/ de apps opcionales
├── migrations/          # cambios entre versiones
├── scripts/             # lint.sh y test.sh (lo que corre la CI)
├── tests/               # suite bats: router, temas, lib.sh, instalador
└── uninstall/           # desinstalador
```

## Desarrollo

```bash
omakux lint   # shellcheck sobre los 68 scripts
omakux test   # lint + 79 tests bats
```

(atajos: `scripts/lint.sh` y `scripts/test.sh`, lo mismo que corre la CI)

Los tests corren en un **sandbox** (`HOME`, `OMAKUX_STATE` y `PATH` propios, con
`gsettings`/`curl`/`magick` reemplazados por stubs): no tocan tu sesión real,
tu ni tu instalación. La CI ejecuta lo mismo en un contenedor Ubuntu limpio.

Reglas que la CI hace cumplir:

- **shellcheck limpio** en todo el bash del repo (`.shellcheckrc`).
- El **help** y las **completions** se generan desde los headers de cada
  comando: si un comando no declara `summary`/`group`, se rompen los dos.
- El **router** resuelve prefijos (`theme set` → `omakux-theme-set`), y todo
  comando expone `# omakux:summary` y `# omakux:group` (si no, el help se rompe).
- **Nada se escribe en dry-run**: ni sellos de fase, ni configs, ni estado.
- `seed`/`backup_file` respaldan antes de sobreescribir.
- Toda paleta define la lista mínima de colores (`omakux theme lint`).
- El **manifest** de temas solo renderiza targets cuyo requisito se cumple.
- `config/dotfiles` no se desvía del instalador: un test cruza sus destinos
  con los `seed` de `install/*.sh` y los renders del manifest de temas.

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
