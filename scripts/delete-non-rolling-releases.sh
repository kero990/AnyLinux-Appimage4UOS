#!/usr/bin/env bash
set -euo pipefail

keep_tag="${1:-${RELEASE_TAG:-latest}}"

if ! command -v gh >/dev/null 2>&1; then
  printf 'gh is required to delete old releases\n' >&2
  exit 1
fi

mapfile -t release_tags < <(gh release list --limit 1000 --json tagName --jq '.[].tagName')

for tag in "${release_tags[@]}"; do
  [[ -n "$tag" ]] || continue
  [[ "$tag" == "$keep_tag" ]] && continue
  printf 'Deleting non-rolling release: %s\n' "$tag"
  gh release delete "$tag" --cleanup-tag --yes
done
