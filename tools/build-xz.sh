#!/usr/bin/env bash
set -euo pipefail

version="${XZ_VERSION:-5.8.1}"
build_dir="${BUILD_DIR:?BUILD_DIR is required}"
stage_dir="${STAGE_DIR:?STAGE_DIR is required}"
cc="${CC:-gcc}"
cflags="${CFLAGS:-}"
ldflags="${LDFLAGS:-}"
host="${HOST_TRIPLE:-i386-linux-musl}"
build="${BUILD_TRIPLE:-x86_64-linux-gnu}"

archive="xz-${version}.tar.xz"
url="https://github.com/tukaani-project/xz/releases/download/v${version}/${archive}"
archive_sha256="${XZ_SHA256:-0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e}"
src_root="${build_dir}/src"
work_root="${build_dir}/work"
install_root="${build_dir}/install/xz"

mkdir -p "$src_root" "$work_root" "$install_root" "$stage_dir/usr/bin"
[[ -f "${src_root}/${archive}" ]] || curl -fsSL "$url" -o "${src_root}/${archive}"
echo "${archive_sha256}  ${src_root}/${archive}" | sha256sum -c -

rm -rf "${work_root}/xz"
mkdir -p "${work_root}/xz"
tar -xf "${src_root}/${archive}" -C "${work_root}/xz"
src_dir="$(find "${work_root}/xz" -mindepth 1 -maxdepth 1 -type d | head -n1)"

rm -rf "${install_root}" && mkdir -p "${install_root}"

(
  cd "$src_dir"
  CC="$cc" CFLAGS="$cflags" LDFLAGS="$ldflags" \
    ./configure --host="$host" --build="$build" --prefix=/usr --disable-shared --enable-static
  make -j"$(nproc)"
  make DESTDIR="$install_root" install
)

find "$stage_dir/usr/bin" -mindepth 1 ! -name '.gitkeep' -delete
for bin in xz unxz xzcat lzma unlzma; do
  install -m 0755 "$install_root/usr/bin/$bin" "$stage_dir/usr/bin/$bin"
done
