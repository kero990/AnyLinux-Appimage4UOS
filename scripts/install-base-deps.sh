#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

packages=(
  base-devel
  git
  kvantum
  libxcb
  libxcursor
  libxi
  libxkbcommon
  libxkbcommon-x11
  libxrandr
  libxtst
  lxqt-qtplugin
  qt6ct
  qt6-tools
  wget
  xorg-server-xvfb
  zsync
)

if command -v pacman-key >/dev/null 2>&1; then
  pacman-key --init || true
  pacman-key --populate archlinux || true
  pacman-key --populate archlinuxarm || true
fi

"$repo_root/scripts/configure-pacman-ci.sh"
pacman -Syu --noconfirm "${packages[@]}"
