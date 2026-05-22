# Waveshare ESP32S3 Ethernet — Partition Tables

No Waveshare-specific custom partition table is currently tracked.

The canonical Waveshare environment currently uses:

```ini
board_build.partitions = ${esp32.extreme_partitions}
```

If a future Waveshare revision needs a target-specific partition CSV, place it in
this directory and reference it from `../platformio.env.ini`.
