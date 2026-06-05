#!/usr/bin/env bash
set -euo pipefail

package="${1:?Usage: build-package.sh <package> [target-arch]}"
target_arch="${2:-$(uname -m)}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_dir="$repo_root/packages/$package"
build_script="$package_dir/build.sh"

if [[ ! -x "$build_script" ]]; then
  printf 'Missing executable build script: %s\n' "$build_script" >&2
  exit 1
fi

version="${VERSION:-$("$repo_root/scripts/package-version.sh" "$package")}"

export PACKAGE_NAME="$package"
export PACKAGE_DIR="$package_dir"
export REPO_ROOT="$repo_root"
export TARGET_ARCH="$target_arch"
export VERSION="$version"
export BUILD_DIR="${BUILD_DIR:-$repo_root/build/$package/$target_arch}"
export OUTPUT_DIR="${OUTPUT_DIR:-$repo_root/dist/$package/$target_arch}"

case "$BUILD_DIR" in
  "$repo_root"/build/*) rm -rf "$BUILD_DIR" ;;
  *) printf 'Refusing to clean unexpected BUILD_DIR: %s\n' "$BUILD_DIR" >&2; exit 1 ;;
esac

case "$OUTPUT_DIR" in
  "$repo_root"/dist/*) rm -rf "$OUTPUT_DIR" ;;
  *) printf 'Refusing to clean unexpected OUTPUT_DIR: %s\n' "$OUTPUT_DIR" >&2; exit 1 ;;
esac

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
"$build_script"
