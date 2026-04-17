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
archive_sha256="${BZIP2_SHA256:-ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269}"
src_root="${build_dir}/src"
work_root="${build_dir}/work"
install_root="${build_dir}/install/bzip2"
archive_path="${src_root}/${archive}"

mkdir -p "$src_root" "$work_root" "$install_root" "$stage_dir/usr/bin"
download_archive() {
  curl -fsSL "$url" -o "$archive_path"
}

[[ -f "$archive_path" ]] || download_archive
if ! echo "${archive_sha256}  ${archive_path}" | sha256sum -c - >/dev/null 2>&1; then
  echo "[SRC] checksum mismatch for ${archive}; redownloading" >&2
  rm -f -- "$archive_path"
  download_archive
fi
echo "${archive_sha256}  ${archive_path}" | sha256sum -c -

rm -rf "${work_root}/bzip2"
mkdir -p "${work_root}/bzip2"
tar -xf "$archive_path" -C "${work_root}/bzip2"
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
