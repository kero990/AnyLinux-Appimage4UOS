#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: assert-package-output.sh <package> <arch>}"
arch="${2:?Usage: assert-package-output.sh <package> <arch>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$repo_root/dist/$package/$arch"

shopt -s nullglob
appimages=("$output_dir"/*.AppImage)

if (( ${#appimages[@]} == 0 )); then
  printf 'No AppImage found in %s\n' "$output_dir" >&2
  exit 1
fi

printf 'Package output:\n'
printf '  %s\n' "${appimages[@]}"
