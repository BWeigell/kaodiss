#!/usr/bin/env sh
# Installs this folder as a local Typst package, without Typst Universe.
#
#   scripts/install-local.sh          copy the files to @local/kaodiss:<version>
#                                     and make the template import @local
#                                     (for users of a downloaded copy)
#   scripts/install-local.sh --link   symlink this folder as @preview/kaodiss:<version>,
#                                     so that the template (which imports @preview)
#                                     uses the working copy (development)
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

if [ "$mode" = link ]; then namespace=preview; else namespace=local; fi
target="$packages/$namespace/kaodiss/$version"
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
  # documents created with `typst init @local/kaodiss:...` import the local copy
  find "$target/template" -name '*.typ' | while read -r f; do
    sed "s|@preview/kaodiss:|@local/kaodiss:|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
fi

echo "Installed @$namespace/kaodiss:$version ($mode) -> $target"
if [ -d "$here/fonts" ]; then
  echo "Fonts are included in $target/fonts: install them, or pass --font-path."
else
  echo "Install the fonts TeX Gyre Pagella, Pagella Math and Heros (see README.md)."
fi
