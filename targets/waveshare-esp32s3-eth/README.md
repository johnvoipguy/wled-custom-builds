# Waveshare ESP32-S3-ETH firmware guide

This page is the quick user entrypoint for Waveshare ESP32-S3-ETH firmware in this repo.

## Get firmware

1. Open releases: https://github.com/johnvoipguy/wled-custom-builds/releases
2. Download the Waveshare ESP32-S3-ETH asset for your target line.

## Which file should I flash?

- `.app.bin` for OTA updates on an already-running device.
- `.full.bin` for first-time USB/UART flash or recovery.

## Flashing

### OTA

Use WLED UI: Settings -> Security & Updates -> Manual OTA.

### UART (first-time / recovery)

```sh
esptool.py --chip esp32s3 write_flash 0x0000 <your-file>.full.bin
```

## Troubleshooting

- Wrong network behavior or missing Ethernet: verify you flashed the Waveshare target build.
- OTA failures: flash `.full.bin` over UART and retry setup.

## More target details

- v16 active line notes (WLED 16.0.1, W5500 hardware-socket Ethernet): [targets/waveshare-esp32s3-eth/v16/notes.md](v16/notes.md) — not yet validated on physical hardware, compiles clean.
- v15 line notes (WLED 0.15.x, preserved/frozen): [targets/waveshare-esp32s3-eth/v15/notes.md](v15/notes.md)
- Shared target config (v15 line only — v16 has its own env fragment, see v16/notes.md): [targets/waveshare-esp32s3-eth/shared](shared)
