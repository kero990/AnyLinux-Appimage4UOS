#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: install-package-deps.sh <package>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_dir="$repo_root/packages/$package"
install_script="$package_dir/install.sh"

if [[ ! -d "$package_dir" ]]; then
  printf 'Unknown package: %s\n' "$package" >&2
  exit 1
fi

"$repo_root/scripts/configure-pacman-ci.sh"

if [[ -x "$install_script" ]]; then
  "$install_script"
fi
