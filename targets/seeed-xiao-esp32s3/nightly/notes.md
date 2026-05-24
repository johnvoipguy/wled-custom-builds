# Seeed Xiao ESP32S3 — v15 notes

Version directories are **deltas only**. All target-wide metadata and base
configuration live in `../shared/` and that directory is the source of truth
for this target.

## Layering model

```
targets/seeed-xiao-esp32s3/
  shared/                   ← source of truth for all Seeed Xiao ESP32S3 builds
    platformio.env.ini      ← canonical PlatformIO environment definition
    partitions/             ← target partition tables
    usermods/               ← target usermods
  v15/                      ← THIS DIRECTORY: v15-specific deltas only
    notes.md
  v16/                      ← v16-specific deltas only
    notes.md
```

## v15-specific notes

- WLED line: `0.15.x`
- PlatformIO env: `seeed_xiao_esp32s3v2` (defined in `../shared/platformio.env.ini`)
- This directory replaces the old habit of keeping a long-lived Xiao branch or nested clone.
- Add v15-specific partition overrides or usermods here only when they genuinely
  differ from `shared/`; do not duplicate the full target definition.
