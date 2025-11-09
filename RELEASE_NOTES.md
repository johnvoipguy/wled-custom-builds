# 🎉 Release Notes

## v0.15.1-waveshare.1 (November 9, 2025)

### 🆕 Initial Release

Custom WLED build specifically for the **Waveshare ESP32-S3-ETH** development board.

### ✨ Features

- **Hardware Ethernet Support** via W5500 SPI chip
  - 10/100Mbps wired connectivity
  - Pre-configured pin mappings for Waveshare board
  - DHCP enabled by default
  
- **WiFi Fallback**
  - Automatic failover if Ethernet cable disconnected
  - Configurable via WLED WiFi settings
  
- **Audio Reactive Ready**
  - Full support for sound-reactive effects
  - Compatible with common I2S and analog microphones
  
- **Production Ready**
  - Based on stable WLED v0.15.1
  - Tested on Waveshare ESP32-S3-ETH hardware
  - Comprehensive documentation included

### 📥 Download

Two binary options available in `build_output/release/`:

1. **`WLED_0.15.1_Waveshare_S3_ETH_FULL.bin`** (1.5MB) ⭐ Recommended
   - Complete image with bootloader + partitions + application
   - Flash to address `0x0`
   - Best for first-time installation
   
2. **`WLED_0.15.1_Waveshare_S3_ETH.bin`** (1.4MB)
   - Application only
   - Flash to address `0x10000`
   - For OTA updates or when bootloader already present

### 🔧 Configuration

#### Hardware Specifications
- **Board**: Waveshare ESP32-S3-ETH
- **MCU**: ESP32-S3-WROOM-1-N16R8
- **Flash**: 16MB
- **PSRAM**: 8MB Octal SPI
- **Ethernet**: W5500 (SPI-based)

#### Pin Configuration
| Function | GPIO |
|----------|------|
| W5500 CS | 10 |
| W5500 MOSI | 11 |
| W5500 MISO | 13 |
| W5500 SCLK | 12 |
| W5500 RST | 14 |
| W5500 INT | 4 |
| LED Data | 48 (default) |

#### Network Settings
- Navigate to **Config → WiFi Setup**
- Select **"Waveshare ESP32-S3-ETH"** from Ethernet Type dropdown (Type 13)
- Ethernet will be used as primary network interface
- WiFi available as backup

### 📊 Build Statistics

- **Flash Usage**: 67.3% (1,412,361 / 2,097,152 bytes)
- **RAM Usage**: 17.0% (55,640 / 327,680 bytes)
- **Build Time**: ~34 seconds (after initial setup)

### 🛠️ Technical Details

#### Code Changes
- Added `initW5500Ethernet()` function in `wled00/network.cpp`
- Implemented network priority: W5500 → ETH → WiFi in `Network.cpp`
- Added board configuration entry (type 13) to `ethernetBoards[]`
- Updated web UI with Waveshare option in Ethernet dropdown
- Created combined binary build script

#### Dependencies
- Arduino Ethernet Library (W5500 support)
- ESP32-S3 Arduino Core v2.0.9 (ESP-IDF 4.4.4)
- All standard WLED libraries

### 📚 Documentation

New comprehensive documentation added:

- **README.md** - User guide with flashing instructions and troubleshooting
- **BUILDING.md** - Developer guide for building and customizing firmware
- **README_W5500.md** - Technical details (deprecated, see README.md)

### 🐛 Known Issues

None at this time. Please report issues on GitHub!

### 🔮 Future Plans

- Audio reactive examples and configuration guides
- Additional board variants (LilyGO T-ETH, etc.)
- Performance optimizations
- Advanced network features

### 📖 Upgrade Notes

#### From Stock WLED
This is a fresh installation. Settings will not be preserved. Backup your configuration before flashing!

#### From Previous Builds
Not applicable - this is the first release.

### 🙏 Acknowledgments

- **Aircoookie** - WLED project creator
- **WLED Community** - Amazing effects and support
- **Waveshare** - ESP32-S3-ETH hardware platform
- **WIZnet** - W5500 Ethernet chip

### 📞 Support

- **Documentation**: See [README.md](README.md) and [BUILDING.md](BUILDING.md)
- **Issues**: [GitHub Issues](https://github.com/johnvoipguy/wled-custom-builds/issues)
- **Discussions**: [GitHub Discussions](https://github.com/johnvoipguy/wled-custom-builds/discussions)
- **WLED Discord**: https://discord.gg/wled

---

## Checksums

### SHA256

```
# Generate with: sha256sum build_output/release/*.bin

<to be added when creating GitHub release>
```

---

<div align="center">

**Happy Flashing! 🚀**

[View on GitHub](https://github.com/johnvoipguy/wled-custom-builds) | [Download Binaries](build_output/release/)

</div>
