# Seeed Xiao ESP32S3 — v16 notes

Version directories are **deltas only**. All target-wide metadata and base
configuration live in `../shared/` and that directory is the source of truth
for this target.

## Layering model

```
targets/seeed-xiao-esp32s3/
  shared/                   ← source of truth for all Seeed Xiao ESP32S3 builds
    platformio.env.ini      ← canonical PlatformIO environment definition
    partitions/             ← partition table notes/reference
    usermods/               ← enabled usermod notes
  v15/                      ← v15-specific deltas only
  v16/                      ← THIS DIRECTORY: v16-specific deltas only
    notes.md
    assets/
      legacy/               ← preserved validated firmware binaries (see README there)
```

## v16-specific notes

- WLED line: `16.x / main`
- All preserved historical firmware for Seeed Xiao ESP32S3 is v16 — there are no v15 Seeed binaries.
- PlatformIO env: `seeed_xiao_esp32s3v2` (defined in `../shared/platformio.env.ini`)
- Use `scripts/apply-target.sh --target seeed-xiao-esp32s3 --version v16 --workspace <path>`
  to stage target assets into a WLED workspace.
- Use the manifest and scripts in this repository instead of maintaining a separate Xiao-only repo clone.
- Keep generated firmware, `.pio`, and nested repos outside the repository.
- Add v16-specific items here only when they genuinely differ from `shared/`.

## Preserved legacy firmware

Validated historical firmware binaries live under `assets/legacy/`. See
[`assets/legacy/README.md`](assets/legacy/README.md) for the full inventory, provenance,
and flashing instructions.
