# WLED Custom Builds

This repository is being restructured into a neutral, multi-target home for custom WLED build metadata on top of `main`.

## Target highlights

- **Waveshare ESP32-S3-ETH:** legacy custom W5500 SPI Ethernet support is documented in `targets/waveshare-esp32s3-eth/v15/notes.md` (documentation only in this repository so far; no port in this PR).
- **SP530E salvage:** `targets/sp530e/` currently carries the salvaged partition CSV and LED status usermods.
- **Seeed Xiao ESP32S3:** current build notes/status live under `targets/seeed-xiao-esp32s3/`.

## Repository direction

- `main` is the canonical branch.
- The new layout is target/version oriented under `targets/`.
- Legacy branch-per-version and clone-per-version workflows are deprecated and are not the recommended path forward.
- Generated artifacts, nested repositories, `.pio`, and other build outputs should stay out of git.

## Starter layout

```text
manifests/
  build-matrix.yml
scripts/
  apply-target.sh
  build-target.sh
  legacy/
targets/
  sp530e/
  seeed-xiao-esp32s3/
  waveshare-esp32s3-eth/
```

## Targets

- `sp530e`
- `seeed-xiao-esp32s3`
- `waveshare-esp32s3-eth`

Each target starts with `shared/` assets plus `v15/` and `v16/` note folders so future work can land in one canonical repository instead of long-lived hardware/version branches.

## Legacy scripts

Legacy shell scripts now live in `scripts/legacy/` as reference material only:

- `quick_setup_wled.sh`
- `quick_setup_wled-seeed-xiao.sh`
- `upgrade_wled_version.sh`
- `wled_manager.sh`

They are preserved to document the old repo-sprawl workflow, but the supported path is now:

1. describe target/version combinations in `manifests/build-matrix.yml`
2. stage reusable assets under `targets/<target>/`
3. use `scripts/apply-target.sh` and `scripts/build-target.sh`

## Starter workflow

`.github/workflows/build.yml` now includes a matrix-planning job for the new target/version layout while preserving the existing reusable WLED build entry point.

## Notes on salvaged assets

The initial scaffold carries forward obvious SP530E-specific assets into `targets/sp530e/shared/`:

- custom partition CSV: `WLED_ESP32C3_4MB_audioreactive.csv`
- usermods: `boot_status_led`, `wifi_status_led`

See the per-target `notes.md` files for starter guidance on where additional target-specific work should land next.
