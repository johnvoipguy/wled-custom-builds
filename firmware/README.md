# WLED Firmware for Waveshare ESP32-S3-ETH

## Current Release: v1.0 - Dual Interface (WiFi + Ethernet)

### Files

- **`WLED_Waveshare_ESP32-S3-ETH_v1.0_DualInterface_YYYYMMDD_FULL.bin`**  
  Complete firmware including bootloader and partitions. Use for initial flash or recovery.

- **`WLED_Waveshare_ESP32-S3-ETH_v1.0_DualInterface_YYYYMMDD_OTA.bin`**  
  Firmware only for OTA (Over-The-Air) updates via web interface.

## Flashing Instructions

### Using esptool.py (Recommended)

**Full Flash** (first time or recovery):
```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 921600 \
  write_flash 0x0 WLED_Waveshare_ESP32-S3-ETH_*_FULL.bin
```

**OTA Update** (if already running WLED):
```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 921600 \
  write_flash 0x10000 WLED_Waveshare_ESP32-S3-ETH_*_OTA.bin
```

Replace `/dev/ttyACM0` with your serial port:
- **Linux/Mac**: `/dev/ttyUSB0`, `/dev/ttyACM0`, or similar
- **Windows**: `COM3`, `COM4`, etc.

### Initial Setup

1. **First boot** (no Ethernet cable):
   - AP opens: `WLED-ETH-Config` (no password)
   - Connect to AP: http://4.3.2.1
   - Configure WiFi SSID/password
   - Save & Reboot

2. **With Ethernet cable connected**:
   - Gets two IP addresses (check router DHCP leases)
   - WiFi: Full web interface
   - Ethernet: UDP protocols for LED control

## Features

- ✅ W5500 Ethernet support
- ✅ Dual-interface operation (WiFi + Ethernet)
- ✅ 8 LED output channels
- ✅ MQTT enabled
- ✅ AudioReactive usermod
- ✅ E1.31, Art-Net, DDP support

See main README.md for detailed capabilities and limitations.
