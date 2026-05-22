# Seeed Xiao ESP32S3 — v16 Legacy Preserved Firmware Assets

## Why these files are here

These firmware binaries are **intentionally preserved historical validated outputs**.
They represent substantial manual testing and regression effort on the Seeed Xiao ESP32S3
target and are retained so that known-good firmware remains visible and recoverable.

These are **not** the canonical build configuration source. The source of truth for the
Seeed Xiao ESP32S3 build lives under `targets/seeed-xiao-esp32s3/shared/`.

## Files

| File | Size | Notes |
|---|---|---|
| `WLED_16.0.0_SEEED-XIAO-ESP32S3-V2.bin` | ~1.1 MB | App-only binary, v2 env (`SEEED-XIAO-ESP32S3-V2`), from `build_output/release/` |
| `WLED_16.0.0_SEEED-XIAO-ESP32S3.bin` | ~1.1 MB | App-only binary, original seeed env (`SEEED-XIAO-ESP32S3`), from `build_output/release/` |
| `WLED_seeed_xiao_esp32s3v2_App_Latest.bin` | ~1.1 MB | App-only binary from GitHub release `seeed_xiao_esp32s3v2-v20260521-222612`, suitable for OTA updates |
| `WLED_seeed_xiao_esp32s3v2_Full_Latest.bin` | ~1.2 MB | Full firmware (bootloader + partitions + app) from GitHub release, for UART first-time flash |
| `BUILD_INFO.txt` | ~1 KB | Build metadata from the GitHub release: commit, branch, flashing instructions. Note: the file listing inside lists the full build directory contents including files not preserved here (e.g. `WLED_seeed_xiao_esp32s3_Full_Latest.bin` without the `v2` suffix is an earlier build not separately preserved). The `v2` files are the ones kept. |

## Provenance

- `WLED_16.0.0_SEEED-XIAO-ESP32S3-V2.bin` and `WLED_16.0.0_SEEED-XIAO-ESP32S3.bin`:
  recovered from `build_output/release/` (commit `8c3dd499`, branch `seeed-xiao-16.0.0`),
  removed from the top-level `build_output/` folder by PR #17 (the main hardening PR).
  Moved here to preserve them in a deliberate, target-owned location.

- `WLED_seeed_xiao_esp32s3v2_App_Latest.bin` and `WLED_seeed_xiao_esp32s3v2_Full_Latest.bin`:
  downloaded from GitHub release tag `seeed_xiao_esp32s3v2-v20260521-222612`, built from
  commit `e4c5870`, branch `seeed-xiao-16.0.0`. These are the most complete validated
  release outputs and include full UART-flash firmware.

## Flashing

### OTA update (existing installation)
Upload `WLED_seeed_xiao_esp32s3v2_App_Latest.bin` via WLED web interface:
Settings → Security & Updates → Manual OTA

### UART first-time flash (new board)
```sh
esptool.py --chip esp32s3 write_flash 0x0000 WLED_seeed_xiao_esp32s3v2_Full_Latest.bin
```

## Important notes

- These assets are **not automatically regenerated** and must be manually updated when new
  validated builds are completed.
- Future generated firmware outputs should **not** be committed into arbitrary top-level
  folders (`build_output/`, `builds/`). Use this target-owned `assets/` area or publish
  them to GitHub Releases and reference them here.
- The canonical build configuration (PlatformIO env, partitions reference, usermod notes)
  lives in `targets/seeed-xiao-esp32s3/shared/`.
