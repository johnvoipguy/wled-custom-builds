# Waveshare ESP32S3 Ethernet — shared target source of truth

This directory is the canonical home for Waveshare ESP32-S3-ETH target metadata
that is reusable across WLED versions.

## Current canonical content

- `platformio.env.ini` — canonical `waveshare_esp32s3_eth` PlatformIO environment
  definition (root `platformio.ini` copy is compatibility only).
- `partitions/` — placeholder for Waveshare-specific partition CSV files when needed.
- `usermods/` — placeholder for Waveshare-specific usermods when needed.

No Waveshare-specific custom partition CSV files or Waveshare-owned usermod source
are currently tracked in this repository.
