# UICD HUB75 S3 firmware guide

This page is the quick user entrypoint for the UICD HUB75 S3 target in this repo.

This target uses a custom sequential HUB75 wiring layout for this specific devkit, not the stock
MoonHub pinout.

## Get firmware

1. Open releases: https://github.com/johnvoipguy/wled-custom-builds/releases
2. Download the UICD HUB75 S3 asset for the line you want.

## Which file should I flash?

- `.app.bin` for OTA updates on an already-running device.
- `.full.bin` for first-time USB/UART flash or recovery.

## Which line should I use?

- `v16` is the stable pinned line based on WLED `v16.0.0`.
- `v17` tracks upstream WLED `main` and moves as upstream changes.

If you want the more reproducible build, use `v16`. If you want the newer moving line, use `v17`.

## Flashing

### OTA

Use WLED UI: Settings -> Security & Updates -> Manual OTA.

### UART (first-time / recovery)

```sh
esptool.py --chip esp32s3 write_flash 0x0000 <your-file>.full.bin
```

## HUB75 pinout used by this target

Both `v16` and `v17` compile with this wiring:

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

## More target details

- v16 notes: [targets/uicd-hub75-s3/v16/notes.md](v16/notes.md)
- v17 notes: [targets/uicd-hub75-s3/v17/notes.md](v17/notes.md)
- Default build manifest: [targets/uicd-hub75-s3/shared/build.default.json](shared/build.default.json)
