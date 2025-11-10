# 🌟 WLED for Waveshare ESP32-S3-ETH

<div align="center">

![WLED Version](https://img.shields.io/badge/WLED-v0.15.1-blue)
![Hardware](https://img.shields.io/badge/Hardware-Waveshare%20ESP32--S3--ETH-green)
![Ethernet](https://img.shields.io/badge/Ethernet-W5500%20SPI-orange)
![License](https://img.shields.io/badge/License-MIT-purple)

**Rock-solid Ethernet connectivity for your LED installations** 🚀

*Custom WLED build specifically configured for the Waveshare ESP32-S3-ETH board with W5500 hardware Ethernet*

[📥 Download Latest](#-quick-start-get-flashing) | [🔧 Build Your Own](#-building-from-source) | [📖 Documentation](#-configuration) | [❓ Support](#-troubleshooting)

</div>

---

## ✨ Why This Build?

✅ **True Hardware Ethernet** - W5500 SPI chip for reliable, low-latency networking  
✅ **WiFi Fallback** - Automatic failover if Ethernet cable disconnected  
✅ **Pre-Configured Pins** - Board-specific setup, just flash and go!  
✅ **Audio Reactive Ready** - Full support for sound-reactive effects  
✅ **Production Ready** - Based on stable WLED v0.15.1 release  
✅ **Large Flash** - 16MB flash with plenty of room for presets and effects

Perfect for permanent installations where WiFi isn't reliable or you need guaranteed network stability!

---

## 🎯 Supported Hardware

### Waveshare ESP32-S3-ETH Development Board

<details>
<summary>📋 Board Specifications</summary>

- **MCU**: ESP32-S3-WROOM-1-N16R8 (Dual-core Xtensa LX7 @ 240MHz)
- **Flash**: 16MB
- **PSRAM**: 8MB Octal SPI
- **Ethernet**: W5500 10/100Mbps via SPI
- **WiFi**: 802.11 b/g/n (2.4GHz)
- **Bluetooth**: BLE 5.0
- **USB**: Native USB CDC (no serial chip needed!)
- **Board Link**: [Waveshare ESP32-S3-ETH](https://www.waveshare.com/wiki/ESP32-S3-ETH)

</details>

### W5500 Pin Mapping (Pre-wired on Board)

| Function | GPIO | Note |
|----------|------|------|
| W5500 MISO | 12 | SPI Data In |
| W5500 MOSI | 11 | SPI Data Out |
| W5500 SCLK | 13 | SPI Clock |
| W5500 CS | 14 | Chip Select |
| W5500 INT | 10 | Interrupt |
| W5500 RST | 9 | Hardware Reset |

*Source: [Waveshare ESP32-S3-ETH Wiki](https://www.waveshare.com/wiki/ESP32-S3-ETH)*

### 8-Channel LED Output Configuration

This build supports **8 simultaneous LED data outputs** for massive installations!

| Channel | GPIO | Max LEDs/Channel* |
|---------|------|-------------------|
| Channel 1 | 48 | 500+ |
| Channel 2 | 47 | 500+ |
| Channel 3 | 38 | 500+ |
| Channel 4 | 39 | 500+ |
| Channel 5 | 40 | 500+ |
| Channel 6 | 41 | 500+ |
| Channel 7 | 42 | 500+ |
| Channel 8 | 1 | 500+ |

*Total LED count limited by available RAM/PSRAM, not individual channel limits*

### Audio Reactive Configuration

| Function | GPIO | Type |
|----------|------|------|
| Audio Input | 4 | I2S Digital Microphone |

### Default WLED Pins

| Function | GPIO | Configurable |
|----------|------|--------------|
| Boot Button | 0 | ❌ Hardware |

---

## 🚀 Quick Start (Get Flashing!)

### 📥 Download Pre-Built Firmware

**Latest Release Files** (in `build_output/release/`):

1. **`WLED_0.15.1_Waveshare_S3_ETH_FULL.bin`** ⭐ **RECOMMENDED**
   - Complete image with bootloader + partitions + app
   - Flash to address `0x0`
   - **Use this for first-time setup!**
   - Size: ~1.5MB

2. **`WLED_0.15.1_Waveshare_S3_ETH.bin`**
   - Application only (for OTA updates)
   - Flash to address `0x10000`
   - Use this to preserve settings during updates

---

### 💾 Flashing Instructions

<details>
<summary>⚡ <b>Method 1: ESPTool (Command Line - Recommended)</b></summary>

**Why ESPTool?** Cross-platform, reliable, scriptable, and no GUI bloat!

#### Install ESPTool

**Option A - Python (All Platforms):**
```bash
pip install esptool
```

**Option B - Standalone Windows Executable:**
Download from [ESPTool Releases](https://github.com/espressif/esptool/releases/latest)
- Get `esptool-vX.X.X-windows-amd64.zip`
- Extract and use `esptool.exe`

#### Flash the Firmware

**Full Image (First Time Setup):**
```bash
# Linux/Mac
esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 WLED_0.15.1_Waveshare_S3_ETH_FULL.bin

# Windows
esptool.py --chip esp32s3 --port COM3 --baud 921600 ^
  write_flash 0x0 WLED_0.15.1_Waveshare_S3_ETH_FULL.bin
```

**App Only Update (Preserves Settings):**
```bash
# Linux/Mac
esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x10000 WLED_0.15.1_Waveshare_S3_ETH.bin

# Windows  
esptool.py --chip esp32s3 --port COM3 --baud 921600 ^
  write_flash 0x10000 WLED_0.15.1_Waveshare_S3_ETH.bin
```

**💡 Tip:** If you get errors, try lower baud rate: `--baud 460800` or `--baud 115200`

</details>

<details>
<summary>🪟 <b>Method 2: Web Flasher (Browser-Based)</b></summary>

**Easiest option - no installation needed!**

1. Visit [ESP Web Tools](https://espressif.github.io/esptool-js/)
2. Connect your Waveshare board via USB-C
3. Click **Connect** and select the serial port
4. Choose `WLED_0.15.1_Waveshare_S3_ETH_FULL.bin`
5. Set offset to `0x0`
6. Click **Program**

Works in Chrome, Edge, and Opera browsers!

</details>

<details>
<summary>🪟 <b>Method 3: ESP Flash Download Tool (GUI)</b></summary>

**Note:** While functional, we recommend ESPTool or Web Flasher for better reliability.

1. Download [Espressif Flash Download Tool](https://www.espressif.com/en/support/download/other-tools)
2. Launch and select **ESP32-S3**
3. Connect your Waveshare board via USB-C
4. Configure:
   - Add `WLED_0.15.1_Waveshare_S3_ETH_FULL.bin` at address `0x0`
   - Select your COM port
   - Set baud rate: `460800` (or `921600` for faster)
5. Click **START**
6. Wait for "FINISH" message

**First time flashing?** Hold the **BOOT** button while connecting USB, then release after Flash Tool connects.

</details>

<details>
<summary>🐧 <b>Linux/Mac - esptool (Command Line)</b></summary>

```bash
# Install esptool if needed
pip install esptool

# Flash the FULL firmware (includes bootloader)
esptool --chip esp32s3 \
        --port /dev/ttyUSB0 \
        --baud 460800 \
        write_flash -z 0x0 \
        WLED_0.15.1_Waveshare_S3_ETH_FULL.bin

# For Mac, port is usually /dev/cu.usbserial-* or /dev/cu.usbmodem*
```

**Troubleshooting Flash:**
- Add `--before default_reset --after hard_reset` if board won't connect
- Hold **BOOT** button during connection if it fails to enter download mode
- Try lower baud rate (`115200`) if you get errors

</details>

<details>
<summary>🌐 <b>Web Flasher (Browser-Based)</b></summary>

Use [ESP Web Tools](https://esp.huhn.me/) for browser-based flashing:

1. Open Chrome/Edge browser (WebSerial required)
2. Visit the Web Flasher site
3. Connect USB, click "Connect"
4. Upload `WLED_0.15.1_Waveshare_S3_ETH_FULL.bin`
5. Flash at offset `0x0`

</details>

---

## 🔧 Configuration

### First Boot Setup

1. **Connect Ethernet cable** to the RJ45 port on the Waveshare board
2. **Power on** - WLED will automatically detect Ethernet and get DHCP address
3. **Find your device:**
   - Check your router's DHCP client list
   - Look for device named `WLED-Waveshare`
   - Or use mDNS: `http://wled-waveshare.local`

4. **Access web interface:**
   - Open browser to `http://<IP-ADDRESS>`
   - Default: No password set (configure one in Settings!)

### Network Settings in WLED

Navigate to **Config → WiFi Setup**:

- **Ethernet Type**: Select **"Waveshare ESP32-S3-ETH"** (Type 13)
- This is pre-configured but you can verify in the dropdown
- DHCP is enabled by default
- WiFi will be available as backup if Ethernet disconnects

### LED Configuration

1. Go to **Config → LED Preferences**
2. Set your LED type (WS2812B, SK6812, etc.)
3. LED data pin is **GPIO 48** by default
4. Configure number of LEDs and other preferences

---

## 🛠️ Building from Source

Want to customize or build your own version? Here's how!

### Prerequisites

```bash
# Install Node.js 20+ (check .nvmrc)
node --version  # Should be 20.x or higher

# Install Python and PlatformIO
pip install -r requirements.txt

# Install Node dependencies (fast, ~5 seconds)
npm ci
```

### Build Process

```bash
# 1. Build web UI first (REQUIRED!)
npm run build

# 2. Build firmware for Waveshare board
pio run -e esp32s3_waveshare_eth

# 3. Find your binaries in:
# - build_output/release/WLED_0.15.1_Waveshare_S3_ETH.bin (app only)
# - .pio/build/esp32s3_waveshare_eth/bootloader.bin
# - .pio/build/esp32s3_waveshare_eth/partitions.bin
# - .pio/build/esp32s3_waveshare_eth/firmware.bin

# 4. Create FULL combined binary (optional)
esptool merge-bin -o WLED_Full.bin \
  --flash-mode qio --flash-freq 80m --flash-size 16MB \
  0x0 .pio/build/esp32s3_waveshare_eth/bootloader.bin \
  0x8000 .pio/build/esp32s3_waveshare_eth/partitions.bin \
  0x10000 .pio/build/esp32s3_waveshare_eth/firmware.bin
```

### Testing

```bash
# Run build system tests
npm test

# Flash to connected device
pio run -e esp32s3_waveshare_eth --target upload

# Monitor serial output
pio device monitor -e esp32s3_waveshare_eth
```

### Customization

The environment configuration is in `platformio.ini`:

```ini
[env:esp32s3_waveshare_eth]
extends = esp32s3
board = esp32-s3-devkitc-1
build_flags = 
    ${esp32s3.build_flags}
    -D WLED_RELEASE_NAME=\"Waveshare_S3_ETH\"
    -D WLED_USE_W5500
    -D W5500_CS_PIN=10
    -D W5500_MOSI_PIN=11
    # ... etc (see platformio.ini for full config)
```

To modify for a different W5500 board, adjust the pin defines in `build_flags`.

---

## 📊 Technical Details

### Memory Usage

- **Flash**: 67.3% used (1,412,361 / 2,097,152 bytes)
- **RAM**: 17.0% used (55,640 / 327,680 bytes)
- Plenty of room for customization and additional features!

### Network Priority

1. **W5500 Ethernet** (Primary) - Used when cable connected
2. **WiFi** (Fallback) - Activates if Ethernet unavailable
3. Automatic failover and reconnection

### Features Included

✅ All standard WLED effects and features  
✅ Audio reactive support (requires microphone)  
✅ E1.31 (sACN) and Art-Net  
✅ DDP (Distributed Display Protocol)  
✅ Alexa/Google Home integration  
✅ MQTT support  
✅ Preset and playlist support  
✅ Sync with other WLED devices  
✅ IR remote support  
✅ Button control (GPIO 0)

---

## 🐛 Troubleshooting

### Ethernet Not Working

**Check the basics:**
1. ✅ Ethernet cable securely connected
2. ✅ Cable is good (test with another device)
3. ✅ Router/switch port is working
4. ✅ LED indicators on RJ45 jack are lit

**Verify in WLED:**
- Go to **Config → WiFi Setup**
- Ethernet Type should show **"Waveshare ESP32-S3-ETH"** (Type 13)
- Check serial console for Ethernet initialization messages

**Serial Debug:**
```bash
pio device monitor -e esp32s3_waveshare_eth -b 115200
```
Look for messages like:
- `W5500 Ethernet initialized`
- `Ethernet link up`
- `Got IP: x.x.x.x`

### WiFi Fallback Not Working

If Ethernet fails, WiFi should activate automatically. To configure:
1. Connect to AP: `WLED-Waveshare` (password: `wled1234`)
2. Configure WiFi credentials in captive portal
3. WiFi will be used when Ethernet is unavailable

### LEDs Not Lighting Up

1. Check **Config → LED Preferences**
2. Verify GPIO 48 is set as data pin
3. Confirm LED type matches your strip (WS2812B, SK6812, etc.)
4. Check 5V power supply to LED strip
5. Common ground between ESP32 and LED strip

### Flash/Upload Failures

- Hold **BOOT** button during connection
- Try lower baud rate: `115200` instead of `460800`
- Check USB cable (must be data cable, not charge-only)
- Install CH340/CP210x drivers if needed
- Try different USB port

### Getting More Help

- Check serial output for error messages
- Review [WLED Knowledge Base](https://kno.wled.ge/)
- Join [WLED Discord](https://discord.gg/wled)
- Open an issue on this repository

---

## 📚 Additional Resources

### Documentation

- [WLED Official Documentation](https://kno.wled.ge/)
- [Waveshare ESP32-S3-ETH Wiki](https://www.waveshare.com/wiki/ESP32-S3-ETH)
- [W5500 Datasheet](https://www.wiznet.io/product-item/w5500/)
- [WLED Effects Guide](https://kno.wled.ge/features/effects/)

### Related Projects

- [WLED Official](https://github.com/Aircoookie/WLED) - Original WLED project
- [WLED Sound Reactive Fork](https://github.com/atuline/WLED) - Audio reactive features
- [xLights](https://xlights.org/) - Professional LED sequencer compatible with WLED

---

## 📜 Version History

### v0.15.1-waveshare.1 (2025-11-09)

- ✨ Initial release based on WLED v0.15.1
- ✅ W5500 SPI Ethernet support
- ✅ Waveshare ESP32-S3-ETH board configuration
- ✅ WiFi fallback functionality
- ✅ Pre-configured pin mappings
- ✅ Full binary with bootloader included

---

## 🤝 Contributing

Found a bug? Want to add a feature? Contributions welcome!

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

---

## 📄 License

This project is based on [WLED](https://github.com/Aircoookie/WLED) by Aircoookie, licensed under the MIT License.

Custom Waveshare ESP32-S3-ETH integration and build configuration by johnvoipguy.

---

## 🙏 Credits

- **Aircoookie** - Original WLED project creator
- **WLED Community** - Amazing effects and features
- **Espressif** - ESP32-S3 platform and tools
- **WIZnet** - W5500 Ethernet chip
- **Waveshare** - ESP32-S3-ETH development board

---

<div align="center">

**Made with ❤️ for the LED community**

⭐ Star this repo if you find it useful!

[⬆ Back to Top](#-wled-for-waveshare-esp32-s3-eth)

</div>
