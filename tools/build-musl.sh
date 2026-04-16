#!/usr/bin/env bash
set -euo pipefail

PREFIX=""
REF="${MUSL_BLUEYOS_REF:-9c0ef094cfc1a330aae80e16d2426ab303c12cf4}"
for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#*=}" ;;
    --ref=*) REF="${arg#*=}" ;;
  esac
done

if [[ -z "$PREFIX" ]]; then
  echo "Usage: $0 --prefix=/path/to/musl-prefix" >&2
  exit 1
fi

mkdir -p "$(dirname "$PREFIX")"

if [[ -d "$PREFIX/include" && -f "$PREFIX/lib/libc.a" && ! -d "$PREFIX/.git" ]]; then
  echo "[MUSL] sysroot already installed at $PREFIX; skipping clone/build."
  exit 0
fi

if [[ ! -d "$PREFIX/.git" ]]; then
  if [[ -e "$PREFIX" ]] && [[ -n "$(find "$PREFIX" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "error: --prefix=$PREFIX exists and is not a git checkout." >&2
    echo "Use an empty prefix directory, or point --prefix at an already-installed sysroot." >&2
    exit 1
  fi
  git clone https://github.com/nzmacgeek/musl-blueyos "$PREFIX"
fi

git -C "$PREFIX" fetch --depth 1 origin "$REF"
git -C "$PREFIX" checkout --detach FETCH_HEAD

make -C "$PREFIX" clean
make -C "$PREFIX" CC="gcc -m32" CFLAGS="-O2 -fno-stack-protector" prefix="$PREFIX" install
