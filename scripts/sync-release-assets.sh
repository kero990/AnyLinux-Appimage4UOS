#!/usr/bin/env bash
set -euo pipefail

tag="${1:-${RELEASE_TAG:-latest}}"
assets_dir="${2:-release-assets}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v gh >/dev/null 2>&1; then
  printf 'gh is required to sync release assets\n' >&2
  exit 1
fi

if [[ ! -d "$assets_dir" ]]; then
  printf 'Release asset directory does not exist: %s\n' "$assets_dir" >&2
  exit 1
fi

target="${RELEASE_TARGET:-${GITHUB_SHA:-}}"
notes='Rolling AppImage release. Assets are replaced per package when versions change.'

if gh release view "$tag" >/dev/null 2>&1; then
  gh release edit "$tag" --title 'Latest AppImages' --notes "$notes" >/dev/null
else
  create_args=("$tag" --title 'Latest AppImages' --notes "$notes")
  if [[ -n "$target" ]]; then
    create_args+=(--target "$target")
  fi
  gh release create "${create_args[@]}"
fi

mapfile -t packages < <("$repo_root/scripts/list-packages.sh")
arches=(x86_64 aarch64)
declare -A update_release

while IFS= read -r meta_file; do
  PACKAGE=''
  ARCH=''
  UPDATE_RELEASE='false'
  # shellcheck disable=SC1090
  source "$meta_file"
  if [[ -n "$PACKAGE" && -n "$ARCH" ]]; then
    update_release["$PACKAGE|$ARCH"]="$UPDATE_RELEASE"
  fi
done < <(find "$assets_dir" -type f -name 'release-meta-*.env' -print)

refresh_existing_assets() {
  mapfile -t existing_assets < <(gh release view "$tag" --json assets --jq '.assets[].name' 2>/dev/null || true)
}

asset_exists() {
  local name="$1"
  local existing
  for existing in "${existing_assets[@]}"; do
    [[ "$existing" == "$name" ]] && return 0
  done
  return 1
}

parse_asset_name() {
  local name="$1"
  local package arch

  PARSED_PACKAGE=''
  PARSED_ARCH=''
  PARSED_KIND=''

  for package in "${packages[@]}"; do
    for arch in "${arches[@]}"; do
      if [[ "$name" == "$package"-*"-$arch.AppImage" ]]; then
        PARSED_PACKAGE="$package"
        PARSED_ARCH="$arch"
        PARSED_KIND='AppImage'
        return 0
      fi
      if [[ "$name" == "$package"-*"-$arch.AppImage.zsync" ]]; then
        PARSED_PACKAGE="$package"
        PARSED_ARCH="$arch"
        PARSED_KIND='AppImage.zsync'
        return 0
      fi
    done
  done

  return 1
}

delete_replaced_assets() {
  local package="$1"
  local arch="$2"
  local kind="$3"
  local keep="$4"
  local existing changed=0

  for existing in "${existing_assets[@]}"; do
    [[ "$existing" == "$keep" ]] && continue
    case "$kind" in
      AppImage)
        [[ "$existing" == "$package"-*"-$arch.AppImage" ]] || continue
        ;;
      AppImage.zsync)
        [[ "$existing" == "$package"-*"-$arch.AppImage.zsync" ]] || continue
        ;;
      *)
        continue
        ;;
    esac

    printf 'Deleting replaced release asset: %s\n' "$existing"
    gh release delete-asset "$tag" "$existing" --yes
    changed=1
  done

  if [[ "$changed" == 1 ]]; then
    refresh_existing_assets
  fi
}

refresh_existing_assets
mapfile -t asset_files < <(find "$assets_dir" -type f \( -name '*.AppImage' -o -name '*.AppImage.zsync' \) -print | sort)

if (( ${#asset_files[@]} == 0 )); then
  printf 'No AppImage assets found in %s\n' "$assets_dir"
  exit 0
fi

for file in "${asset_files[@]}"; do
  [[ -f "$file" ]] || continue
  name="$(basename "$file")"

  if ! parse_asset_name "$name"; then
    printf 'Skipping unrecognized release asset name: %s\n' "$name"
    continue
  fi

  force_update="${update_release["$PARSED_PACKAGE|$PARSED_ARCH"]:-false}"
  delete_replaced_assets "$PARSED_PACKAGE" "$PARSED_ARCH" "$PARSED_KIND" "$name"

  if asset_exists "$name"; then
    if [[ "$force_update" == 'true' ]]; then
      printf 'Replacing rebuilt release asset: %s\n' "$name"
      gh release upload "$tag" "$file" --clobber
      refresh_existing_assets
    else
      printf 'Keeping existing release asset: %s\n' "$name"
    fi
  else
    printf 'Uploading release asset: %s\n' "$name"
    gh release upload "$tag" "$file"
    refresh_existing_assets
  fi
done
