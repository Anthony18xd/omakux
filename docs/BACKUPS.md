# Backups y snapshots

omakux usa **timeshift en modo rsync** (tu `/` es ext4; si fuera btrfs usaríamos snapper).

## Qué se guarda

- **Snapshot diario automático** (comprobación horaria de timeshift) + manual con `omakux snapshot create`
- Retención: 5 diarios / 4 semanales / 6 mensuales
- **Excluido**: `/home`, `/var/cache`, `/var/lib/docker`, `/snap`, `/tmp`… (ver `/etc/timeshift/timeshift.json`)
  → Tus datos personales *no* van dentro del snapshot: haz copia de `/home` aparte (Deja Dup, rsync a un disco).

## Comandos

```bash
omakux snapshot list          # listar
omakux snapshot create "antes de X"
omakux snapshot delete <n>
omakux update                 # crea snapshot antes de actualizar
```

## Restaurar

Timeshift rsync **no** arranca desde GRUB. Para restaurar:

1. Arranca un live USB de Ubuntu.
2. Instala timeshift (`sudo apt install timeshift`).
3. Abre timeshift → pestaña Restore → selecciona snapshot → Restore.
4. Reinicia.

> Si solo algo de `~/.config` se rompió, no hagas restore: `omakux config reset`
> o copia desde `~/.local/state/omakux/backup/`.

## Otras copias

- **Configs omakux pre-instalación**: `~/.local/state/omakux/backup/`
- **Repositorio**: `~/.local/share/omakux` (clonalo a otro sitio o push a git)
