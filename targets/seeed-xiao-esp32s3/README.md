# Seeed Xiao ESP32S3 firmware guide (user focused)

This page is the quick user entrypoint for Seeed Xiao ESP32S3 firmware in this repo.

## Get firmware

1. Open releases: https://github.com/johnvoipguy/wled-custom-builds/releases
2. Download the Seeed Xiao ESP32S3 asset for your target line.

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

## Known-good preserved legacy assets

See: [targets/seeed-xiao-esp32s3/v16/assets/legacy/README.md](v16/assets/legacy/README.md)

## More target details

- Shared config source: [targets/seeed-xiao-esp32s3/shared](shared)
- v15 notes: [targets/seeed-xiao-esp32s3/v15/notes.md](v15/notes.md)
- v16 notes: [targets/seeed-xiao-esp32s3/v16/notes.md](v16/notes.md)
