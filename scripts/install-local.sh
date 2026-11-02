#!/usr/bin/env sh
# Installs this folder as the local Typst package @local/kaodiss:<version>.
#
#   scripts/install-local.sh          copy the files (recommended for users)
#   scripts/install-local.sh --link   symlink instead, so that changes to the
#                                     template take effect immediately (development)
#
# The target directory follows Typst's conventions; TYPST_PACKAGE_PATH
# overrides it (as it does for typst itself).
set -eu

mode=copy
if [ "${1:-}" = "--link" ]; then mode=link; fi

here="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$here/typst.toml")"

if [ -n "${TYPST_PACKAGE_PATH:-}" ]; then
  packages="$TYPST_PACKAGE_PATH"
else
  case "$(uname -s)" in
    Darwin) packages="$HOME/Library/Application Support/typst/packages" ;;
    *) packages="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages" ;;
  esac
fi

target="$packages/local/kaodiss/$version"
mkdir -p "$(dirname "$target")"
rm -rf "$target"
if [ "$mode" = link ]; then
  ln -s "$here" "$target"
else
  mkdir -p "$target"
  # everything except the built example and macOS metadata
  (cd "$here" && find . -type f ! -path './template/main.pdf' ! -path './.git/*' ! -name '.DS_Store' -print) | while read -r f; do
    mkdir -p "$target/$(dirname "$f")"
    cp "$here/$f" "$target/$f"
  done
fi

echo "Installed @local/kaodiss:$version ($mode) -> $target"
if [ -d "$here/fonts" ]; then
  echo "Fonts are included in $target/fonts: install them, or pass --font-path."
else
  echo "Install the fonts TeX Gyre Pagella, Pagella Math and Heros (see README.md)."
fi
