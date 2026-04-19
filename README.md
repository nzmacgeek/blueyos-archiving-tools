# blueyos-archiving-tools

Cross-build and package **tar**, **gzip**, **bzip2**, and **xz** for [BlueyOS](https://github.com/nzmacgeek/biscuits).

Each tool is built against [musl-blueyos](https://github.com/nzmacgeek/musl-blueyos) and staged into a dedicated [dimsim](https://github.com/nzmacgeek/dimsim) package directory.

## Repository layout

```text
Makefile
tools/
  build-musl.sh
  build-tar.sh
  build-gzip.sh
  build-bzip2.sh
  build-xz.sh
tar/
  meta/manifest.json
  payload/
gzip/
  meta/manifest.json
  payload/
bzip2/
  meta/manifest.json
  payload/
xz/
  meta/manifest.json
  payload/
```

## Prerequisites

- `gcc` with 32-bit support (`gcc-multilib` on Debian/Ubuntu)
- `make`, `curl`, `tar`, `xz-utils`, `patch`, `git`
- `dpkbuild` (from `nzmacgeek/dimsim`) for package assembly

## Build flow

```bash
# 1) Build (or provide) musl-blueyos sysroot
make musl

# 2) Build and stage all tools into payload trees
make

# 3) Build .dpk archives for each tool
make dpk
```

Build individual ports:

```bash
make tar
make gzip
make bzip2
make xz
```

Install staged payloads into a target BlueyOS sysroot:

```bash
make install SYSROOT=/mnt/blueyos
```

## Variables

- `MUSL_PREFIX` — musl sysroot/compiler prefix (default: auto-detected)
- `TARGET_TRIPLE` — configure `--host` target (default: `i386-linux-musl`)
- `BUILD_DIR` — build output directory (default: `build`)
- `CC`, `CFLAGS`, `LDFLAGS` — compiler and flags used for all package builds
- `MUSL_BLUEYOS_REF` — pinned musl-blueyos git ref used by `make musl`

Note: `MUSL_PREFIX` must point at a prefix that includes both musl headers/libs and a
musl compiler wrapper (for example `bin/musl-gcc`). If `/opt/blueyos-sysroot/usr`
contains only runtime/sysroot files, the build defaults to `build/musl` and asks you
to run `make musl` first.

Each upstream source archive is validated with SHA256 before extraction. Override
`TAR_SHA256`, `GZIP_SHA256`, `BZIP2_SHA256`, or `XZ_SHA256` only when intentionally
updating to a new verified upstream artifact.
