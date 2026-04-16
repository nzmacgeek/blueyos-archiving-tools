#!/usr/bin/env bash
set -euo pipefail

version="${BZIP2_VERSION:-1.0.8}"
build_dir="${BUILD_DIR:?BUILD_DIR is required}"
stage_dir="${STAGE_DIR:?STAGE_DIR is required}"
cc="${CC:-gcc}"
cflags="${CFLAGS:-}"
ldflags="${LDFLAGS:-}"

archive="bzip2-${version}.tar.gz"
url="https://sourceware.org/pub/bzip2/${archive}"
src_root="${build_dir}/src"
work_root="${build_dir}/work"
install_root="${build_dir}/install/bzip2"

mkdir -p "$src_root" "$work_root" "$install_root" "$stage_dir/usr/bin"
[[ -f "${src_root}/${archive}" ]] || curl -fsSL "$url" -o "${src_root}/${archive}"

rm -rf "${work_root}/bzip2"
mkdir -p "${work_root}/bzip2"
tar -xf "${src_root}/${archive}" -C "${work_root}/bzip2"
src_dir="$(find "${work_root}/bzip2" -mindepth 1 -maxdepth 1 -type d | head -n1)"

rm -rf "${install_root}" && mkdir -p "${install_root}/usr"

(
  cd "$src_dir"
  make clean
  make -j"$(nproc)" CC="$cc" CFLAGS="$cflags" LDFLAGS="$ldflags"
  make PREFIX="$install_root/usr" install
)

find "$stage_dir/usr/bin" -mindepth 1 ! -name '.gitkeep' -delete
for bin in bzip2 bunzip2 bzcat; do
  install -m 0755 "$install_root/usr/bin/$bin" "$stage_dir/usr/bin/$bin"
done
