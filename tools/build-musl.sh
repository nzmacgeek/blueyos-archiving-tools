#!/usr/bin/env bash
set -euo pipefail

PREFIX=""
for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#*=}" ;;
  esac
done

if [[ -z "$PREFIX" ]]; then
  echo "Usage: $0 --prefix=/path/to/musl-prefix" >&2
  exit 1
fi

mkdir -p "$(dirname "$PREFIX")"

if [[ ! -d "$PREFIX/.git" ]]; then
  git clone --depth 1 https://github.com/nzmacgeek/musl-blueyos "$PREFIX"
fi

make -C "$PREFIX" clean
make -C "$PREFIX" CC="gcc -m32" CFLAGS="-O2 -fno-stack-protector" prefix="$PREFIX" install
