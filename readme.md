# WLED Custom Builds

This repository is a neutral, multi-target home for custom WLED build metadata on top of upstream `main`.

## Repository layering model

| Layer | Location | Role |
|---|---|---|
| **Base / upstream defaults** | repo root (`platformio.ini`, workflows, scripts) | Generic WLED build foundation — not target-specific |
| **Target source of truth** | `targets/<target>/shared/` | Canonical home for all target-specific metadata, config, partitions, usermods |
| **Version-specific deltas** | `targets/<target>/v15/`, `targets/<target>/v16/` | Only what differs per WLED version line; reference `shared/`, do not duplicate it |

> **Rule:** If a file is target-specific, it belongs under `targets/<target>/shared/`, not in the root.
> The root `platformio.ini` and scripts are the generic base layer; target directories are the source of truth.

## Target highlights

- **Seeed Xiao ESP32S3:** canonical PlatformIO env and build metadata live in
  `targets/seeed-xiao-esp32s3/shared/platformio.env.ini`. Version notes under
  `v15/` and `v16/` are deltas only.
- **Waveshare ESP32-S3-ETH:** W5500 SPI Ethernet support is documented in
  `targets/waveshare-esp32s3-eth/v15/notes.md`; active migration track.
- **SP530E:** salvaged partition CSV and LED status usermods live in
  `targets/sp530e/shared/`.

## Repository direction

- `main` is the canonical branch.
- The layout is target/version oriented under `targets/`.
- Legacy branch-per-version and clone-per-version workflows are deprecated.
- Generated artifacts, nested repositories, `.pio`, and build outputs must stay out of git.

## Directory layout

```text
manifests/
  build-matrix.yml          ← target/version/env mapping
scripts/
  apply-target.sh           ← stage target assets (usermods, partitions, env fragment) into a workspace
  build-target.sh           ← create temp workspace, apply target, run pio build
  legacy/                   ← old scripts preserved as reference only
targets/
  sp530e/
    shared/                 ← source of truth: partitions, usermods
    v15/  v16/              ← version deltas / notes
  seeed-xiao-esp32s3/
    shared/
      platformio.env.ini    ← canonical Seeed PlatformIO env definition
      partitions/
      usermods/
    v15/  v16/              ← version deltas / notes
  waveshare-esp32s3-eth/
    shared/
    v15/  v16/
platformio.ini              ← generic WLED base (root = upstream defaults, not target-specific)
```

## Starter workflow

1. Describe target/version combinations in `manifests/build-matrix.yml`.
2. Keep target-specific config and assets under `targets/<target>/shared/`.
3. Use `scripts/apply-target.sh` and `scripts/build-target.sh` to stage and build.

```sh
# Stage Seeed assets into an existing WLED workspace
scripts/apply-target.sh --target seeed-xiao-esp32s3 --version v16 --workspace /path/to/wled

# Stage + build in a temporary workspace
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16 --environment seeed_xiao_esp32s3v2
```

## Legacy scripts

Legacy shell scripts live in `scripts/legacy/` as reference material only.
They are preserved to document the old repo-sprawl workflow but are not supported.

## Notes on salvaged assets

The SP530E target carries salvaged assets into `targets/sp530e/shared/`:

- custom partition CSV: `WLED_ESP32C3_4MB_audioreactive.csv`
- usermods: `boot_status_led`, `wifi_status_led`

See the per-target `notes.md` files for guidance on where additional target-specific work should land.
