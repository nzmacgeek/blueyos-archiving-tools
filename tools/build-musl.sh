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

existing_musl_cc=""
for candidate in "$PREFIX/bin/musl-gcc" "$PREFIX/bin/i386-linux-musl-gcc"; do
  if [[ -x "$candidate" ]]; then
    existing_musl_cc="$candidate"
    break
  fi
done

if [[ -d "$PREFIX/include" && -f "$PREFIX/lib/libc.a" && ! -d "$PREFIX/.git" ]]; then
  if [[ -n "$existing_musl_cc" ]] && "$existing_musl_cc" -print-file-name=libc.a >/dev/null 2>&1; then
    echo "[MUSL] sysroot already installed at $PREFIX; skipping clone/build."
    exit 0
  fi
  echo "[MUSL] existing sysroot at $PREFIX has an unusable compiler wrapper." >&2
  if [[ -n "$existing_musl_cc" ]]; then
    echo "       Wrapper check failed: $existing_musl_cc -print-file-name=libc.a" >&2
  else
    echo "       No musl compiler wrapper found under $PREFIX/bin" >&2
  fi
  echo "       Rebuild into a fresh prefix, or point MUSL_PREFIX at a musl checkout." >&2
  exit 1
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

wrapcc_gcc="$PREFIX/bin/musl-host-gcc"
mkdir -p "$PREFIX/bin"

if command -v i686-linux-gnu-gcc >/dev/null 2>&1; then
  real_gcc="$(command -v i686-linux-gnu-gcc)"
  real_gcc_args=""
  build_cc="i686-linux-gnu-gcc"
else
  if ! command -v gcc >/dev/null 2>&1; then
    echo "[MUSL] neither i686-linux-gnu-gcc nor gcc is available on PATH" >&2
    exit 1
  fi
  real_gcc="$(command -v gcc)"
  real_gcc_args="-m32"
  build_cc="gcc -m32"
fi

cat > "$wrapcc_gcc" <<EOF
#!/bin/sh
exec "$real_gcc" $real_gcc_args "\$@"
EOF
chmod +x "$wrapcc_gcc"

make -C "$PREFIX" clean
make -C "$PREFIX" CC="$build_cc" CFLAGS="-O2 -fno-stack-protector" WRAPCC_GCC="$wrapcc_gcc" prefix="$PREFIX" install
