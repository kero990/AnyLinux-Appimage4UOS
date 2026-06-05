#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
packages_dir="$repo_root/packages"

list_packages() {
  if [[ ! -d "$packages_dir" ]]; then
    return 0
  fi

  find "$packages_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

case "${1:-}" in
  --json)
    printf '['
    sep=''
    while IFS= read -r package; do
      [[ -n "$package" ]] || continue
      printf '%s"%s"' "$sep" "$package"
      sep=','
    done < <(list_packages)
    printf ']\n'
    ;;
  ''|--plain)
    list_packages
    ;;
  *)
    printf 'Usage: %s [--json|--plain]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
