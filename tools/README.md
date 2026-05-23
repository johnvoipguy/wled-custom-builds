# Seeed Xiao ESP32S3 — Partition Tables

The Seeed Xiao ESP32S3 uses the standard WLED 8MB partition table:

- **File:** `tools/WLED_ESP32_8MB.csv` (in the repo root `tools/` directory)
- **Reference:** `board_build.partitions = ${esp32.large_partitions}` in `platformio.env.ini`
- **Variable:** `esp32.large_partitions = tools/WLED_ESP32_8MB.csv` (defined in root `platformio.ini`)

The Seeed XIAO ESP32S3 has 8 MB of flash. The standard WLED 8MB layout is used without
modification, which provides OTA-capable dual-app slots and a LittleFS file system partition.

## If you need a custom partition table

If a future version requires a custom partition layout specific to the Seeed target, place
the `.csv` file here and update `platformio.env.ini` to reference it with a relative path
from the PlatformIO workspace root.

Example:
```ini
board_build.partitions = targets/seeed-xiao-esp32s3/shared/partitions/my_custom.csv
```
