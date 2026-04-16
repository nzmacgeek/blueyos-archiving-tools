TOOLS := tar gzip bzip2 xz

TAR_VERSION   ?= 1.35
GZIP_VERSION  ?= 1.13
BZIP2_VERSION ?= 1.0.8
XZ_VERSION    ?= 5.8.1
MUSL_BLUEYOS_REF ?= 9c0ef094cfc1a330aae80e16d2426ab303c12cf4

BUILD_DIR ?= build
ABS_BUILD_DIR := $(if $(filter /%,$(BUILD_DIR)),$(BUILD_DIR),$(CURDIR)/$(BUILD_DIR))

BLUEYOS_SYSROOT ?= /opt/blueyos-sysroot
ifeq ($(origin MUSL_PREFIX),undefined)
  MUSL_PREFIX := $(shell BLUEYOS_SYSROOT="$(BLUEYOS_SYSROOT)" BUILD_DIR="$(ABS_BUILD_DIR)" bash tools/resolve-musl-prefix.sh)
else
  MUSL_PREFIX := $(shell BLUEYOS_SYSROOT="$(BLUEYOS_SYSROOT)" BUILD_DIR="$(ABS_BUILD_DIR)" bash tools/resolve-musl-prefix.sh "$(MUSL_PREFIX)")
endif

TARGET_TRIPLE ?= i386-linux-musl
BUILD_TRIPLE  ?= $(shell gcc -dumpmachine 2>/dev/null || echo x86_64-linux-gnu)

MUSL_GCC := $(MUSL_PREFIX)/bin/musl-gcc
ifeq ($(shell [ -x "$(MUSL_GCC)" ] && echo yes),yes)
  DEFAULT_CC := $(MUSL_GCC)
else
  DEFAULT_CC := gcc
endif
ifeq ($(origin CC),default)
  CC := $(DEFAULT_CC)
else ifeq ($(origin CC),undefined)
  CC := $(DEFAULT_CC)
endif

CFLAGS  ?= -O2 -pipe
LDFLAGS ?= -static

INSTALL_ROOT_INPUT := $(strip $(if $(DESTDIR),$(DESTDIR),$(SYSROOT)))
INSTALL_SYSROOT := $(shell BLUEYOS_SYSROOT="$(BLUEYOS_SYSROOT)" MUSL_PREFIX="$(MUSL_PREFIX)" bash tools/resolve-install-sysroot.sh "$(INSTALL_ROOT_INPUT)" 2>/dev/null)

.RECIPEPREFIX := @
.PHONY: all musl clean dpk help install install-staged $(TOOLS)

.DEFAULT_GOAL := all

all: $(TOOLS)

musl:
@if [ -d "$(MUSL_PREFIX)/include" ] && [ -f "$(MUSL_PREFIX)/lib/libc.a" ] && [ ! -d "$(MUSL_PREFIX)/.git" ]; then \
echo "[MUSL] existing musl sysroot detected under $(MUSL_PREFIX); skipping build"; \
else \
bash tools/build-musl.sh --prefix="$(MUSL_PREFIX)" --ref="$(MUSL_BLUEYOS_REF)"; \
fi

define check_musl
@if [ ! -d "$(MUSL_PREFIX)/include" ] || [ ! -f "$(MUSL_PREFIX)/lib/libc.a" ]; then echo "[MUSL] musl sysroot not found under $(MUSL_PREFIX)"; echo "       Run: make musl (or provide MUSL_PREFIX=/path/to/sysroot)"; exit 1; fi
endef

tar:
@$(call check_musl)
@TAR_VERSION="$(TAR_VERSION)" BUILD_DIR="$(ABS_BUILD_DIR)" STAGE_DIR="$(CURDIR)/tar/payload"   CC="$(CC)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" HOST_TRIPLE="$(TARGET_TRIPLE)" BUILD_TRIPLE="$(BUILD_TRIPLE)"   bash tools/build-tar.sh

gzip:
@$(call check_musl)
@GZIP_VERSION="$(GZIP_VERSION)" BUILD_DIR="$(ABS_BUILD_DIR)" STAGE_DIR="$(CURDIR)/gzip/payload"   CC="$(CC)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" HOST_TRIPLE="$(TARGET_TRIPLE)" BUILD_TRIPLE="$(BUILD_TRIPLE)"   bash tools/build-gzip.sh

bzip2:
@$(call check_musl)
@BZIP2_VERSION="$(BZIP2_VERSION)" BUILD_DIR="$(ABS_BUILD_DIR)" STAGE_DIR="$(CURDIR)/bzip2/payload"   CC="$(CC)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"   bash tools/build-bzip2.sh

xz:
@$(call check_musl)
@XZ_VERSION="$(XZ_VERSION)" BUILD_DIR="$(ABS_BUILD_DIR)" STAGE_DIR="$(CURDIR)/xz/payload"   CC="$(CC)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" HOST_TRIPLE="$(TARGET_TRIPLE)" BUILD_TRIPLE="$(BUILD_TRIPLE)"   bash tools/build-xz.sh

dpk:
@command -v dpkbuild >/dev/null 2>&1 || { echo "[DPK] dpkbuild not found on PATH. Build from nzmacgeek/dimsim"; exit 1; }
@for pkg in $(TOOLS); do \
echo "[DPK] Building $$pkg"; \
tmp_pkg="$(ABS_BUILD_DIR)/dpk-src/$$pkg"; \
rm -rf "$$tmp_pkg"; \
mkdir -p "$(ABS_BUILD_DIR)/dpk-src"; \
cp -a "$$pkg" "$$tmp_pkg"; \
find "$$tmp_pkg/payload" -name '.gitkeep' -type f -delete; \
dpkbuild build "$$tmp_pkg" --output "$(ABS_BUILD_DIR)/dpk"; \
done
@ls -1 "$(ABS_BUILD_DIR)"/dpk/*.dpk

install: all install-staged

define check_install_sysroot
@if [ -z "$(INSTALL_SYSROOT)" ]; then echo "[INSTALL] No target sysroot resolved. Use SYSROOT=/path"; exit 1; fi
@if [ "$(INSTALL_SYSROOT)" = "/" ] || [ "$(INSTALL_SYSROOT)" = "." ]; then echo "[INSTALL] Refusing unsafe sysroot $(INSTALL_SYSROOT)"; exit 1; fi
endef

install-staged:
@$(call check_install_sysroot)
@mkdir -p -- "$(INSTALL_SYSROOT)"
@for payload in tar/payload gzip/payload bzip2/payload xz/payload; do echo "[INSTALL] $$payload -> $(INSTALL_SYSROOT)"; ( cd "$$payload" && tar --exclude='.gitkeep' --exclude='*/.gitkeep' -cf - . ) | ( cd "$(INSTALL_SYSROOT)" && tar -xpf - ); done

clean:
@rm -rf -- "$(ABS_BUILD_DIR)"
@find tar/payload/usr/bin gzip/payload/usr/bin bzip2/payload/usr/bin xz/payload/usr/bin -mindepth 1 ! -name '.gitkeep' -delete

help:
@echo "blueyos-archiving-tools"
@echo ""
@echo "  make            build tar, gzip, bzip2, xz against musl-blueyos"
@echo "  make musl       clone/build musl-blueyos sysroot"
@echo "  make dpk        build .dpk files for tar/gzip/bzip2/xz"
@echo "  make install    install staged payloads into SYSROOT/DESTDIR"
@echo "  make clean      remove build outputs and staged binaries"
@echo ""
@echo "Variables:"
@echo "  MUSL_PREFIX=$(MUSL_PREFIX)"
@echo "  TARGET_TRIPLE=$(TARGET_TRIPLE)"
@echo "  BUILD_DIR=$(BUILD_DIR)"
@echo "  MUSL_BLUEYOS_REF=$(MUSL_BLUEYOS_REF)"
