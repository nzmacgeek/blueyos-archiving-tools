#!/usr/bin/env bash
set -euo pipefail

version="${TAR_VERSION:-1.35}"
build_dir="${BUILD_DIR:?BUILD_DIR is required}"
stage_dir="${STAGE_DIR:?STAGE_DIR is required}"
cc="${CC:-gcc}"
cflags="${CFLAGS:-}"
ldflags="${LDFLAGS:-}"
host="${HOST_TRIPLE:-i386-linux-musl}"
build="${BUILD_TRIPLE:-x86_64-linux-gnu}"

archive="tar-${version}.tar.xz"
url="https://ftp.gnu.org/gnu/tar/${archive}"
archive_sha256="${TAR_SHA256:-6b9824c92deddbd7021801515270211f5252fbd8f57ef926ad45b42e31c2d8c0}"
src_root="${build_dir}/src"
work_root="${build_dir}/work"
install_root="${build_dir}/install/tar"

mkdir -p "$src_root" "$work_root" "$install_root" "$stage_dir/usr/bin"
[[ -f "${src_root}/${archive}" ]] || curl -fsSL "$url" -o "${src_root}/${archive}"
echo "${archive_sha256}  ${src_root}/${archive}" | sha256sum -c -

rm -rf "${work_root}/tar"
mkdir -p "${work_root}/tar"
tar -xf "${src_root}/${archive}" -C "${work_root}/tar"
src_dir="$(find "${work_root}/tar" -mindepth 1 -maxdepth 1 -type d | head -n1)"

rm -rf "${install_root}" && mkdir -p "${install_root}"

(
  cd "$src_dir"
  CC="$cc" CFLAGS="$cflags" LDFLAGS="$ldflags" \
    ./configure --host="$host" --build="$build" --prefix=/usr
  make -j"$(nproc)"
  make DESTDIR="$install_root" install
)

find "$stage_dir/usr/bin" -mindepth 1 ! -name '.gitkeep' -delete
install -m 0755 "$install_root/usr/bin/tar" "$stage_dir/usr/bin/tar"
