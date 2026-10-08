# Seguridad, sudo y qué toca omakux

## Sudo

Por defecto omakux **no** deja `NOPASSWD` en `/etc/sudoers.d`. Todo lo que
requiere root pasa por `sud()` (ver `install/lib.sh`), que primero ejecuta
`confirm_sudo`:

```bash
sudo -n true || sudo -v || die "Se necesita sudo para continuar"
```

Es decir: escribes tu contraseña **una vez** y sudo la cachea (unos 5 minutos).
Si el cache caduca a mitad de un `omakux update`, te la vuelve a pedir.

### Modo desatendido (opcional, bajo tu responsabilidad)

Cualquier proceso que corra como tu usuario puede, con este archivo, ejecutar
cualquier cosa como root: scripts descargados, plugins, agentes de IA. Solo
tiene sentido en una máquina que nadie toca:

```bash
sudo install -m 0440 install/omakux-nopasswd.example /etc/sudoers.d/omakux-nopasswd
sudo visudo -c                     # valida la sintaxis
sudo rm -f /etc/sudoers.d/omakux-nopasswd   # volver a la normalidad
```

## Qué toca omakux (y qué no)

| Zona | Qué hace |
|---|---|
| `~/.config/*` | renderiza templates del tema activo (backup previo en `~/.local/state/omakux/backup/`) |
| `~/.local/share/omakux` | el repo (git) — tu código |
| `~/.local/state/omakux` | estado: sellos de fase, logs, paquetes instalados, wallpapers, backups |
| `/etc/timeshift`, `/etc/apt/apt.conf.d` | solo en la fase `system` (snapshots, auto-updates) |
| `/etc/ufw` | deny incoming / allow outgoing en la fase `system` |
| `gsettings` | tema, acento y fondo de GNOME |
| `/usr/local/bin/omakux` | symlink al router del repo |

**No** toca: `~/.ssh`, claves, tu shell original (queda registrado en
`~/.local/state/omakux/original-shell`), ni tus configs si no cambian (los
archivos ya distintos se respaldan, no se pisan).

## Red

- `ufw` con política **deny incoming / allow outgoing**.
- La fase `check` hace un `curl` a `archive.ubuntu.com` solo para verificar
  conectividad (10 s de timeout, sin descargar nada).

## Restauración

1. Algo pequeño se rompió → `omakux config reset` (respalda tus edits antes).
2. Solo `~/.config` → copia desde `~/.local/state/omakux/backup/`.
3. El sistema → `omakux snapshot list` y restaura con timeshift.
4. Todo → `omakux uninstall` + snapshot de la instalación inicial.
