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

## Available GPIO for Usermods and Custom Peripherals

If you want to add custom usermods (temperature sensors, extra I/O, microphone input, I²C/SPI devices, etc.):

**Available:**
- **GPIO 38–41**: Free for usermod use (I²C, SPI, analog input, PWM, etc.)

**Reserved/Unavailable:**
- GPIO 0–3, 15–18: LED data outputs (8 channels)
- GPIO 4–7: SD card (reserved for future SD card support)
- GPIO 9–14: W5500 Ethernet SPI controller
- GPIO 21: Onboard status LED
- GPIO 33–37: Module PSRAM

To use these pins, modify `platformio.env.ini` or add flags in your local `platformio_override.ini`.

## Which line should I use?

This board has three build lines. If you need DDP/E1.31/MQTT or the web UI to work over the
Ethernet port, **use v17** — on v16, Ethernet only proves link-up/DHCP and carries no WLED
application traffic (see v16 notes for why).

| Line | WLED base | Ethernet model | DDP/E1.31/MQTT/web UI over Ethernet? | Status |
|---|---|---|---|---|
| **v17 (recommended)** | `main` / IDF5 / Core 3.3.8 | native lwIP (`ETH_PHY_W5500`) | Yes | Hardware-validated on two boards |
| v16 | 16.0.1 | W5500 hardware-socket offload | No — Ethernet only carries link-up/DHCP | Hardware-validated |
| v15 | 0.15.x | (preserved/frozen) | — | Preserved, not actively developed |

## More target details

- v17 line notes (WLED `main`, native lwIP W5500 — recommended): [targets/waveshare-esp32s3-eth/v17/notes.md](v17/notes.md)
- v16 line notes (WLED 16.0.1, W5500 hardware-socket Ethernet): [targets/waveshare-esp32s3-eth/v16/notes.md](v16/notes.md) — hardware-validated; see notes for the Ethernet application-traffic limitation.
- v15 line notes (WLED 0.15.x, preserved/frozen): [targets/waveshare-esp32s3-eth/v15/notes.md](v15/notes.md)
- Shared target config (v15 line only — v16/v17 each have their own env fragment, see their notes.md): [targets/waveshare-esp32s3-eth/shared](shared)
