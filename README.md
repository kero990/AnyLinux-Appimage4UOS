# AnyLinux AppImage build scripts

This repository is organized so each application owns its own packaging logic,
while GitHub Actions handles architecture matrices, version caching, artifact
collection, and one rolling release.

## Layout

- `.github/workflows/build-appimages.yml` runs the build and release workflow.
- `scripts/` contains shared orchestration helpers.
- `packages/<name>/` contains package-specific install, version, and build scripts.
- `dist/<name>/<arch>/` is the normalized output directory for generated AppImages.

## Rolling release behavior

The workflow uses one fixed release tag:

```text
latest
```

Every matrix entry detects the package version before building. The generated
AppImage cache key is:

```text
appimage-<package>-<arch>-<version>-<cache_revision>
```

If the key exists, the workflow reuses the cached AppImage. If the key is
missing but the `latest` release already contains the same package, version, and
architecture, the workflow downloads that release asset and saves it back into
the cache. Only when neither source exists does the package rebuild.

During release sync, unchanged assets are kept in place. When a package version
changes, only the matching old assets for that package and architecture are
removed and replaced. Releases other than `latest` are deleted so the repository
keeps a single public release.

To force a rebuild without an upstream version bump, set `REUSE_RELEASE_ASSET=0`
in the package's `package.env` and increase `CACHE_REVISION`. After the rebuilt
asset has been published, set `REUSE_RELEASE_ASSET=1` again for normal reuse.

## Local usage

Inside an Arch-like container:

```bash
scripts/install-base-deps.sh
scripts/install-package-deps.sh krita
VERSION="$(scripts/package-version.sh krita)" scripts/build-package.sh krita "$(uname -m)"
```

Build every package for the current architecture:

```bash
scripts/build-all.sh
```
