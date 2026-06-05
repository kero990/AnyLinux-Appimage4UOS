#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: package-cache-revision.sh <package>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/packages/$package/package.env"

CACHE_REVISION=1
if [[ -f "$env_file" ]]; then
  # shellcheck disable=SC1090
  source "$env_file"
fi

printf '%s\n' "${CACHE_REVISION:-1}"
