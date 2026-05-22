# Waveshare ESP32S3 Ethernet v15

Legacy notes for the custom WLED v0.15.x Waveshare ESP32-S3-ETH implementation with onboard W5500 SPI Ethernet.

## Legacy hardware/profile summary

- Target board profile: **Waveshare ESP32-S3-ETH**
- MCU/memory profile: **ESP32-S3, 16MB flash, 8MB PSRAM**
- Ethernet profile: **onboard W5500 over SPI**
- Legacy PlatformIO environment: `esp32s3_waveshare_eth`
- Legacy behavior flags included `WLED_USE_W5500` and `WLED_ETH_DEFAULT=13`

## Legacy W5500 SPI pin mapping

- MISO: **GPIO 12**
- MOSI: **GPIO 11**
- SCLK: **GPIO 13**
- CS: **GPIO 14**
- INT: **GPIO 10**
- RST: **GPIO 9**

## Legacy network behavior (user-visible)

- WiFi remained the path for the web UI, WebSockets, HTTP/JSON API, and OTA.
- Ethernet (W5500) was used for UDP LED protocols and MQTT.
- The split-interface design was driven by limitations in the legacy AsyncTCP / AsyncWebServer integration path.

## Legacy observations to revalidate before treating as canonical

- Legacy material included observed LED output mappings (for example, GPIO48 in prior setup scripts/notes); treat these as provisional and re-test on hardware before migration sign-off.
- A legacy audio-reactive microphone setup/note existed in prior custom work and should also be revalidated on current hardware/firmware baselines.

## Migration reference and likely implementation hotspots

- Legacy source tree reference: `/workspace/wled-waveshare-esp32s3-eth`
- Likely hotspots from legacy implementation inspection:
  - `platformio.ini`
  - `wled00/network.cpp`
  - `wled00/wled.cpp`
  - `wled00/wled.h`
  - `wled00/const.h`
  - `wled00/cfg.cpp`
  - `wled00/set.cpp`
  - `wled00/xml.cpp`
  - `wled00/src/dependencies/network/Network.cpp`

This file is intentionally documentation-only for migration planning. No W5500 porting changes are introduced in this PR.
