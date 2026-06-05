#!/usr/bin/env bash
set -euo pipefail

target_arch="${1:-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r package; do
  [[ -n "$package" ]] || continue
  unset VERSION
  "$repo_root/scripts/install-package-deps.sh" "$package"
  "$repo_root/scripts/build-package.sh" "$package" "$target_arch"
done < <("$repo_root/scripts/list-packages.sh")
