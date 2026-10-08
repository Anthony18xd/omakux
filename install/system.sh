#!/usr/bin/env bash
# omakux:summary System hardening: snapshots, firewall, trim, auto-updates
# omakux:group install
# sourced by install.sh — do not execute directly

confirm_sudo
apt_install_list "$OMAKUX_PATH/install/packages/system.apt"

# --- timeshift: snapshots del sistema (rsync en ext4) ---
log "configurando timeshift (snapshots)"
root_dev="$(findmnt -no SOURCE /)"
root_dev="$(readlink -f "$root_dev")"
ts_json=/etc/timeshift/timeshift.json
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY timeshift config + snapshot inicial en $root_dev"
else
  if ! has timeshift; then
    apt_install timeshift
  fi
  if [ ! -f "$ts_json" ]; then
    # esquema timeshift >= 25.x: todos los escalares como STRINGS + backup_device_uuid
    ts_uuid="$(blkid -s UUID -o value "$root_dev" 2>/dev/null || true)"
    [ -n "$ts_uuid" ] || die "no se pudo leer la UUID de $root_dev"
    sud mkdir -p /etc/timeshift
    sud tee "$ts_json" >/dev/null <<EOF
{
  "backup_device_uuid": "$ts_uuid",
  "parent_device_uuid": "",
  "do_first_run": "false",
  "btrfs_mode": "false",
  "include_btrfs_home": "false",
  "include_btrfs_home_for_restore": "false",
  "stop_cron_emails": "true",
  "schedule_monthly": "false",
  "schedule_weekly": "false",
  "schedule_daily": "true",
  "schedule_hourly": "false",
  "schedule_boot": "false",
  "count_monthly": "6",
  "count_weekly": "4",
  "count_daily": "5",
  "count_hourly": "6",
  "count_boot": "5",
  "snapshot_size": "0",
  "snapshot_count": "0",
  "date_format": "%Y-%m-%d %H:%M",
  "exclude": [
    "/home/",
    "/tmp/",
    "/var/tmp/",
    "/var/cache/",
    "/var/lib/docker/",
    "/var/lib/flatpak/",
    "/snap/",
    "/swapfile",
    "/media/",
    "/mnt/",
    "/proc/",
    "/sys/",
    "/dev/",
    "/run/",
    "/lost+found/"
  ],
  "exclude-apps": []
}
EOF
    ok "timeshift configurado en $root_dev (uuid: $ts_uuid, retención: 5/4/6)"
  else
    ok "timeshift ya configurado"
  fi
  # snapshot inicial + timer diario
  if ! sud timeshift --list 2>/dev/null | grep -q "Snapshot"; then
    log "creando snapshot inicial (puede tardar varios minutos)…"
    sud timeshift --create --yes --comments "omakux: instalacion inicial" >/dev/null 2>&1 ||
      warn "el snapshot inicial falló (se reintenta: omakux snapshot create)"
  fi
  sud systemctl enable --now timeshift.timer >/dev/null 2>&1 || true
fi

# --- firewall ---
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY ufw default deny incoming / allow outgoing + enable"
else
  sud ufw default deny incoming >/dev/null
  sud ufw default allow outgoing >/dev/null
  sud ufw --force enable >/dev/null
  ok "ufw activo (deny incoming, allow outgoing)"
fi

# --- SSD trim ---
run sudo systemctl enable --now fstrim.timer || true
ok "fstrim.timer activo"

# --- actualizaciones automáticas de seguridad ---
if [ "$OMAKUX_DRY" = "1" ]; then
  log "DRY habilitar unattended-upgrades"
else
  apt_install unattended-upgrades
  sud sed -i 's|^//\s*Unattended-Upgrade::Enable ".*"|Unattended-Upgrade::Enable "true"|' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null || true
  if ! grep -q 'Unattended-Upgrade::Enable "true"' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
    sud tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
  fi
  sud systemctl enable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
  ok "unattended-upgrades (solo seguridad) activo"
fi

# --- audio pipewire (por si acaso) ---
apt_install pipewire pipewire-pulse wireplumber pavucontrol

# --- servicios extra ---
if [ "$OMAKUX_DRY" != "1" ]; then
  sud systemctl enable --now NetworkManager >/dev/null 2>&1 || true
  if has bluetoothctl; then
    sud systemctl enable --now bluetooth >/dev/null 2>&1 || true
  fi
fi

ok "sistema endurecido"
