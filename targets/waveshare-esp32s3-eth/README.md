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

- v15 active line notes: [targets/waveshare-esp32s3-eth/v15/notes.md](v15/notes.md)
- Shared target config: [targets/waveshare-esp32s3-eth/shared](shared)
