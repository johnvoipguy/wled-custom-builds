# Waveshare ESP32S3 Ethernet — v15 notes

Reference notes for the custom WLED `0.15.x` Waveshare ESP32-S3-ETH build line.

## Active line status

- **Active/preserved line for this target:** `v15`
- WLED line: `0.15.x`
- Canonical PlatformIO environment: `waveshare_esp32s3_eth`
- Canonical env definition: `../shared/platformio.env.ini`

## Layering model

```text
targets/waveshare-esp32s3-eth/
  shared/                   ← source of truth for target metadata/config
    platformio.env.ini      ← canonical Waveshare PlatformIO environment
    partitions/             ← target-specific partition CSV files (none tracked currently)
    usermods/               ← target-specific usermods (none tracked currently)
  v15/                      ← THIS DIRECTORY: v15-specific deltas + preserved firmware assets
    notes.md
    assets/
      legacy/               ← intended home for preserved validated v15 firmware binaries
```

## Hardware/profile summary

- Target board profile: **Waveshare ESP32-S3-ETH**
- MCU/memory profile: **ESP32-S3, 16MB flash, 8MB PSRAM**
- Ethernet profile: **onboard W5500 over SPI**
- Key flags: `WLED_USE_W5500`, `WLED_ETH_DEFAULT=13`

## W5500 SPI pin mapping

- MISO: **GPIO 12**
- MOSI: **GPIO 11**
- SCLK: **GPIO 13**
- CS: **GPIO 14**
- INT: **GPIO 10**
- RST: **GPIO 9**

## Network behavior to revalidate on hardware

- WiFi remained the path for Web UI, WebSockets, HTTP/JSON API, and OTA.
- Ethernet (W5500) was used for UDP LED protocols and MQTT.
- Re-test interface split assumptions on current baseline before calling this fully canonical.
