# WLED Firmware for Waveshare ESP32-S3-ETH

## Current Release: WLED 0.15.1 - Waveshare ESP32-S3-ETH

### Files

- **`WLED_0.15.1_Waveshare_ETH_FULL.bin`** (1.5 MB)  
  Complete firmware including bootloader and partitions. Use for initial flash or recovery.

- **`WLED_0.15.1_Waveshare_ETH_OTA.bin`** (1.4 MB)  
  Firmware only for OTA (Over-The-Air) updates via web interface.

- **`WLED_0.15.1_Waveshare_ETH_SHA256.txt`**  
  SHA256 checksums for firmware verification.

### What's New in 0.15.1
- ✅ **Hot-plug Ethernet detection** - Plug cable after boot and it initializes within 500ms!
- ✅ Fixed pin allocation bug preventing hot-plug initialization
- ✅ Improved DHCP timeout (15 seconds) for reliable network initialization
- ✅ Seamless dual-interface operation (WiFi + Ethernet simultaneously)
- ✅ Works with cable plugged before or after boot

## Flashing Instructions

### Using esptool.py (Recommended)

**Full Flash** (first time or recovery):
```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 460800 \
  write_flash 0x0 WLED_0.15.1_Waveshare_ETH_FULL.bin
```

**OTA Update** (if already running WLED):
```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 460800 \
  write_flash 0x10000 WLED_0.15.1_Waveshare_ETH_OTA.bin
```

Replace `/dev/ttyACM0` with your serial port:
- **Linux/Mac**: `/dev/ttyUSB0`, `/dev/ttyACM0`, or similar
- **Windows**: `COM3`, `COM4`, etc.

### Initial Setup

1. **First boot without Ethernet cable**:
   - WiFi AP opens: `WLED-AP` (password: `wled1234`)
   - Connect to AP and navigate to: http://4.3.2.1
   - Configure your WiFi SSID/password in Config → WiFi Setup
   - Save & Reboot
   - Device connects to your WiFi network

2. **First boot with Ethernet cable connected**:
   - Gets IP via DHCP on Ethernet (check router)
   - WiFi AP still opens for configuration
   - Connect to AP, configure WiFi, save & reboot
   - Device gets two IPs (one WiFi, one Ethernet)

3. **Hot-plug Ethernet** (plug cable after boot):
   - Detects cable within 500ms
   - Automatically initializes and gets DHCP address
   - Both interfaces work simultaneously

### Network Behavior

- **WiFi IP**: Full web interface, WebSockets, all protocols
- **Ethernet IP**: UDP protocols (E1.31, Art-Net, DDP), MQTT
- Both interfaces can receive LED control commands
- Web interface accessible from either IP address

## Features

- ✅ WLED v0.15.1 base
- ✅ W5500 Ethernet with hot-plug detection
- ✅ Dual-interface operation (WiFi + Ethernet simultaneously)
- ✅ 8 LED output channels (GPIO: 48, 47, 38, 39, 40, 41, 42, 1)
- ✅ MQTT enabled
- ✅ AudioReactive usermod (I2S microphone on GPIO 4)
- ✅ E1.31, Art-Net, DDP support on both interfaces
- ✅ 15-second DHCP timeout for reliable network initialization

## Checksums (SHA256)

```
bd4d36bc6726d599814fd98ec68a467674fc6ee3f345d98e7195076a38e30059  WLED_0.15.1_Waveshare_ETH_FULL.bin
ebd32c116d568be372c2ef79d2db17dd1166fa7405926f2027c46422fabd8011  WLED_0.15.1_Waveshare_ETH_OTA.bin
```

Verify after download:
```bash
sha256sum -c WLED_0.15.1_Waveshare_ETH_SHA256.txt
```

See main README.md for detailed capabilities and limitations.
