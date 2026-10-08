#!/usr/bin/env bash
# omakux:summary Install Docker engine + compose and add user to docker group
# omakux:group install
# sourced by terminal.sh — do not execute directly

apt_install docker.io docker-compose-v2
add_user_to_group docker

if [ "$OMAKUX_DRY" != "1" ] && has docker; then
  # sin daemon todavía si no se ha reiniciado sesión: no es un error
  ok "docker $(docker --version 2>/dev/null | head -1)"
fi
