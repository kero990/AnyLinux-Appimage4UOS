#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: package-version.sh <package>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version_script="$repo_root/packages/$package/version.sh"

if [[ ! -x "$version_script" ]]; then
  printf 'Missing executable version script: %s\n' "$version_script" >&2
  exit 1
fi

"$version_script"
