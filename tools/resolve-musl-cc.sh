#!/usr/bin/env bash
set -euo pipefail

MUSL_PREFIX="${MUSL_PREFIX:-}"
TARGET_TRIPLE="${TARGET_TRIPLE:-i386-linux-musl}"
BUILD_DIR="${BUILD_DIR:-$PWD/build}"

candidates=()

if [[ -n "$MUSL_PREFIX" ]]; then
  candidates+=("$MUSL_PREFIX/bin/musl-gcc")
  candidates+=("$MUSL_PREFIX/bin/${TARGET_TRIPLE}-gcc")
fi

candidates+=("$BUILD_DIR/musl/bin/musl-gcc")
candidates+=("$BUILD_DIR/musl/bin/${TARGET_TRIPLE}-gcc")

if command -v musl-gcc >/dev/null 2>&1; then
  candidates+=("$(command -v musl-gcc)")
fi
if command -v "${TARGET_TRIPLE}-gcc" >/dev/null 2>&1; then
  candidates+=("$(command -v "${TARGET_TRIPLE}-gcc")")
fi

for cc in "${candidates[@]}"; do
  if [[ -x "$cc" ]]; then
    printf '%s\n' "$cc"
    exit 0
  fi
done

exit 0
