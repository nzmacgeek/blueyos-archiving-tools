#!/usr/bin/env bash
set -euo pipefail

BLUEYOS_SYSROOT="${BLUEYOS_SYSROOT:-/opt/blueyos-sysroot}"
BUILD_DIR="${BUILD_DIR:-$PWD/build}"
INPUT="${1:-}"

if [[ -n "$INPUT" ]]; then
  printf '%s\n' "$INPUT"
  exit 0
fi

if [[ -d "$BLUEYOS_SYSROOT/usr/include" && -f "$BLUEYOS_SYSROOT/usr/lib/libc.a" ]] \
  && { [[ -x "$BLUEYOS_SYSROOT/usr/bin/musl-gcc" ]] || [[ -x "$BLUEYOS_SYSROOT/usr/bin/i386-linux-musl-gcc" ]]; }; then
  printf '%s\n' "$BLUEYOS_SYSROOT/usr"
  exit 0
fi

printf '%s\n' "$BUILD_DIR/musl"
