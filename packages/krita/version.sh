#!/usr/bin/env bash
set -euo pipefail

if ! pacman -Q krita >/dev/null 2>&1; then
  printf 'krita is not installed; run scripts/install-package-deps.sh krita first\n' >&2
  exit 1
fi

pacman -Q krita | awk '{print $2}' | sed 's/-[^-]*$//'
