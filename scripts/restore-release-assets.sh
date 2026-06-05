#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: restore-release-assets.sh <package> <arch> <version> [release-tag]}"
arch="${2:?Usage: restore-release-assets.sh <package> <arch> <version> [release-tag]}"
version="${3:?Usage: restore-release-assets.sh <package> <arch> <version> [release-tag]}"
tag="${4:-${RELEASE_TAG:-latest}}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_env="$repo_root/packages/$package/package.env"
output_dir="$repo_root/dist/$package/$arch"
repo="${GITHUB_REPOSITORY:-}"

REUSE_RELEASE_ASSET=1
if [[ -f "$package_env" ]]; then
  # shellcheck disable=SC1090
  source "$package_env"
fi

if [[ "${REUSE_RELEASE_ASSET:-1}" != "1" ]]; then
  printf 'Release asset reuse is disabled for %s\n' "$package"
  exit 1
fi

if [[ -z "$repo" ]]; then
  printf 'GITHUB_REPOSITORY is not set; cannot restore release assets\n' >&2
  exit 1
fi

mkdir -p "$output_dir"

asset="${package}-${version}-${arch}.AppImage"
base_url="https://github.com/${repo}/releases/download/${tag}"

download_asset() {
  local name="$1"
  local destination="$2"
  local tmp="${destination}.tmp"
  local args=(-q -O "$tmp")

  rm -f "$tmp"
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    args=(--header="Authorization: Bearer ${GITHUB_TOKEN}" "${args[@]}")
  fi

  if wget "${args[@]}" "${base_url}/${name}"; then
    mv "$tmp" "$destination"
    return 0
  fi

  rm -f "$tmp"
  return 1
}

if ! download_asset "$asset" "$output_dir/$asset"; then
  rm -f "$output_dir/$asset" "$output_dir/$asset.tmp"
  printf 'No matching AppImage found in release %s: %s\n' "$tag" "$asset"
  exit 1
fi

chmod +x "$output_dir/$asset"

download_asset "${asset}.zsync" "$output_dir/${asset}.zsync" || rm -f "$output_dir/${asset}.zsync" "$output_dir/${asset}.zsync.tmp"
printf 'Restored %s from release %s\n' "$asset" "$tag"
