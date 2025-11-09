# WLED ESP32-S3 W5500 Ethernet Build

Custom WLED firmware for ESP32-S3 with W5500 SPI Ethernet support, based on WLED v0.15.1.

## Supported Hardware

**Waveshare ESP32-S3-ETH** - ESP32-S3 development board with onboard W5500 Ethernet chip

## Features

- ✅ W5500 SPI Ethernet (10/100Mbps)
- ✅ WiFi fallback support
- ✅ Audio reactive (with compatible microphone)
- ✅ 16MB Flash / 8MB PSRAM
- ✅ All standard WLED features

## Pin Configuration

### W5500 Ethernet Pins (Pre-wired on Waveshare board)
- **CS**: GPIO 10
- **MOSI**: GPIO 11
- **MISO**: GPIO 13
- **SCLK**: GPIO 12
- **RST**: GPIO 14
- **INT**: GPIO 4

### LED Control Pins
- **LED Data**: GPIO 48 (default, configurable in WLED)
- **Onboard RGB**: GPIO 48

### Other Pins
- **Boot Button**: GPIO 0

## Installation

### 1. Flash the Firmware

Download the latest firmware: `build_output/release/WLED_0.15.1_ESP32S3_W5500.bin`

**Option A: Using esptool.py (Command Line)**
```bash
esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 460800 write_flash -z 0x0 WLED_0.15.1_ESP32S3_W5500.bin
```

**Option B: Using ESP Flash Tool (GUI)**
1. Download [ESP Flash Tool](https://www.espressif.com/en/support/download/other-tools)
2. Select ESP32-S3
3. Load the .bin file at address `0x0`
4. Click "Start"

**Option C: Using Web Flasher**
1. Visit https://install.wled.me
2. Select "Custom firmware"
3. Upload `WLED_0.15.1_ESP32S3_W5500.bin`

### 2. Initial Setup

1. **Power on** the ESP32-S3-ETH board
2. **Connect Ethernet cable** to your network
3. The board will automatically get an IP via DHCP
4. Check your router for the assigned IP address (looks for hostname "WLED-xxxx")

### 3. Configure WLED

1. Open web browser to `http://<IP-ADDRESS>`
2. Go to **Config** → **WiFi Setup**
3. Set **Ethernet Type** to: **ESP32-S3Dev-W5500** (option 13)
4. Click **Save & Reboot**

## Network Priority

The firmware checks network interfaces in this order:
1. **W5500 Ethernet** (if connected)
2. **WiFi** (fallback if Ethernet unavailable)

## LED Strip Connection

Connect your LED strip data pin to **GPIO 48** (or configure different pin in WLED settings).

**Example WS2812B Connection:**
- LED Data → GPIO 48
- LED +5V → External 5V power supply
- LED GND → ESP32-S3 GND + Power supply GND

⚠️ **Important**: Always use external power for LED strips. Do not power LEDs from the ESP32-S3 board.

## Troubleshooting

### Ethernet Not Working
1. **Check cable**: Ensure Ethernet cable is properly connected
2. **Check router**: Verify DHCP is enabled on your router
3. **Check settings**: In WLED Config → WiFi Setup, verify "Ethernet Type" is set to "ESP32-S3Dev-W5500"
4. **Check serial output**: Connect USB and monitor serial at 115200 baud for debug messages

### WiFi Fallback
If Ethernet fails, the board will automatically fall back to WiFi:
1. Connect to WiFi AP: `WLED-AP`
2. Configure WiFi credentials in captive portal
3. Board will connect to your WiFi network

### Static IP Configuration
To use static IP instead of DHCP:
1. Go to **Config** → **WiFi Setup**
2. Enable **Static IP**
3. Enter: IP Address, Gateway, Subnet Mask
4. Click **Save & Reboot**

## Building from Source

```bash
# Clone repository
git clone -b esp32s3-w5500-v15.1 https://github.com/johnvoipguy/wled-custom-builds.git
cd wled-custom-builds

# Install dependencies
npm ci
pip install -r requirements.txt

# Build firmware
pio run -e esp32s3_w5500

# Firmware output: .pio/build/esp32s3_w5500/firmware.bin
```

## Technical Specifications

- **Flash Usage**: 67.3% (1,412,361 bytes)
- **RAM Usage**: 17.0% (55,640 bytes)
- **Base Version**: WLED v0.15.1
- **Platform**: ESP32-S3 (Xtensa LX7)
- **Arduino Core**: v2.0.9 (ESP-IDF 4.4.4)

## Branch Information

- **Branch**: `esp32s3-w5500-v15.1`
- **Repository**: https://github.com/johnvoipguy/wled-custom-builds
- **Base**: WLED v0.15.1 stable release

## Support

For issues specific to this W5500 build:
- Open an issue on: https://github.com/johnvoipguy/wled-custom-builds/issues

For general WLED questions:
- WLED Discord: https://discord.gg/QAh7wJHrRM
- WLED Documentation: https://kno.wled.ge

## License

This project inherits the WLED license (MIT).
See the main WLED repository for full license details.
