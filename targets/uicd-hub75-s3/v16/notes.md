# UICD HUB75 S3 — v16 notes

This target packages the MoonHub HUB75 ESP32-S3 board as a repo-managed target overlay instead
of relying on a hand-edited root `platformio.ini` entry.

This board does not use the stock MoonHub wiring. The target applies a v16 patch so the compiled
HUB75 mapping matches this project's clean sequential header layout.

## Layering model

```text
targets/uicd-hub75-s3/
  shared/
    build.default.json
  v16/
    build.json
    notes.md
    platformio.env.ini   <- canonical v16 environment definition
```

## v16 target definition

- WLED line: `v16.0.0`
- PlatformIO environment: `uicd_hub75_s3`
- Base board: `lilygo-t7-s3`
- HUB75 macro: `UICPAL_S3_EFFICIENT_ROW`
- Source overlay: `v16/patches/0001-use-custom-sequential-hub75-pinout.patch`
- Flash layout: `${esp32.extreme_partitions}` for 16MB flash
- I2S mic defaults: disabled to avoid HUB75 conflicts (`I2S_SDPIN=-1`, `I2S_CKPIN=-1`, `I2S_WSPIN=-1`, `MCLK_PIN=-1`)

## HUB75 pinout used by this target

This target compiles with this wiring:

- `R1=4`
- `G1=5`
- `B1=6`
- `R2=7`
- `G2=8`
- `B2=9`
- `A=38`
- `B=39`
- `C=40`
- `D=41`
- `E=42`
- `LAT=13`
- `OE=14`
- `CLK=10`

GPIO `10`, `13`, and `14` are owned by HUB75 on this devkit (`CLK`, `LAT`, `OE`), so the target disables the I2S mic pins rather than reusing them.

## Source and library overlays

This target needs a v16 source patch, but no vendored library overlay.

- WLED v16.0.0 contains a stock ESP32-S3/MoonHub mapping path, but this target uses a custom `UICPAL_S3_EFFICIENT_ROW` branch with board-specific pin assignment.
- `v16/patches/0001-use-custom-sequential-hub75-pinout.patch` rewires that path to this board's actual header order.
- Standard HUB75 dependencies come from `${hub75.lib_deps}` in the environment fragment above.

If upstream WLED changes the `MOONHUB_S3_PINOUT` implementation in a way that breaks this board,
add a version-scoped patch under `v16/patches/` instead of editing the workspace root.
