# UICD HUB75 S3 — v17 notes

This line tracks upstream WLED `main` and is therefore a moving target.

## v17 target definition

- WLED ref: `main`
- WLED repo: `https://github.com/wled/WLED.git`
- PlatformIO environment: `uicd_hub75_s3`
- Base board: `lilygo-t7-s3`
- HUB75 macro: `UICPAL_S3_EFFICIENT_ROW`
- Source overlay: `v17/patches/0001-use-custom-sequential-hub75-pinout.patch`
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

## Drift expectations

Because this line tracks `main`, upstream commits can break the patch or the environment.
Use `scripts/check-target-patches.sh --target uicd-hub75-s3 --version v17` periodically
to catch source drift before builds fail.

## Source and library overlays

This target currently needs only a version-scoped `bus_manager.cpp` patch and no vendored
library overlay.
