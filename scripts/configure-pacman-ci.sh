#!/usr/bin/env bash
set -euo pipefail

pacman_conf="${PACMAN_CONF:-/etc/pacman.conf}"

if [[ ! -f "$pacman_conf" ]]; then
  exit 0
fi

# GitHub-hosted container jobs may not allow pacman's Landlock download sandbox.
if ! grep -Eq '^[[:space:]]*DisableSandbox([[:space:]]|$)' "$pacman_conf"; then
  printf '\nDisableSandbox\n' >> "$pacman_conf"
fi

# Arch containers may set DownloadUser=alpm; user switching can fail in CI.
sed -i -E 's/^[[:space:]]*(DownloadUser[[:space:]]*=)/#\1/' "$pacman_conf"
