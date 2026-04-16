#!/usr/bin/env bash
set -euo pipefail

input="${1:-}"
musl_prefix="${MUSL_PREFIX:-}"
blueyos_sysroot="${BLUEYOS_SYSROOT:-/opt/blueyos-sysroot}"

if [[ -n "$input" ]]; then
  printf '%s\n' "$input"
  exit 0
fi

if [[ -d "$blueyos_sysroot" ]]; then
  printf '%s\n' "$blueyos_sysroot"
  exit 0
fi

if [[ -n "$musl_prefix" && "${musl_prefix##*/}" == "usr" ]]; then
  printf '%s\n' "${musl_prefix%/usr}"
  exit 0
fi

echo "Unable to resolve install sysroot" >&2
exit 1
