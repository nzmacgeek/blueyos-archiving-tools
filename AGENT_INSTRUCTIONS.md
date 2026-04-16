# Agent Instructions for blueyos-archiving-tools

This repository follows the broader BlueyOS workflow used across the `nzmacgeek` ecosystem.

## Cross-repo references

Before changing build, ABI, or packaging behavior, check:

- `nzmacgeek/biscuits` (kernel and userspace expectations)
- `nzmacgeek/musl-blueyos` (toolchain and libc compatibility)
- `nzmacgeek/dimsim` (package format and install semantics)
- `nzmacgeek/blueyos-bash` (current cross-build + dimsim packaging patterns)

## Packaging requirements

- Build userspace tools against `musl-blueyos`
- Stage files into per-package `payload/` trees
- Keep package metadata in `meta/manifest.json`
- Build `.dpk` archives with `dpkbuild`

## Scope discipline

- Keep changes minimal and focused on this repository
- Do not change unrelated behavior in other projects
