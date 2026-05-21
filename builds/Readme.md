# SP530E Firmware Builds v0.16.0-alpha

This directory contains **ready-to-flash firmware** for SP530E controllers. No hunting through artifacts!

## 📥 Latest Builds

### 🚀 For Initial UART Flashing
- **[WLED_SP530E_Full_Latest.bin](./latest/WLED_SP530E_Full_Latest.bin)** - Complete firmware with bootloader + partitions + app

### 🔄 For OTA Updates  
- **[WLED_SP530E_App_Latest.bin](./latest/WLED_SP530E_App_Latest.bin)** - App only (faster OTA updates)

### 🔧 Individual Components
- **[Bootloader.bin](./latest/Bootloader.bin)** - ESP32-C3 bootloader
- **[Partitions.bin](./latest/Partitions.bin)** - Partition table for 4MB flash
- **[App.bin](./latest/App.bin)** - WLED application firmware

---

## 📋 What Do I Need?

### 🔌 First Time Setup (New SP530E)
**Download**: `WLED_SP530E_Full_Latest.bin` (1.2MB)
**Flash Command**:
```bash
esptool.py --chip esp32c3 --port COM3 --baud 460800 write_flash --secure 0x0000 WLED_SP530E_Full_Latest.bin
```
*(Replace COM3 with your serial port)*


### 🔄 Updating Existing SP530E  
⚠️ **WRNING!!!!: v0.16.0 Requires flashing firmware via UART ONLY!! You cannot OTA to this version! remember to use --secure after write_flash **. Recommend erase-flash prior firmware writing!!! ⚠️
**Download**: `WLED_SP530E_App_Latest.bin` (1.2MB)
**Upload via**: WLED web interface → Settings → Security & Updates → Manual OTA

---

## ⚡ Quick Flash Commands

### ESP Tool (Command Line)
```bash
# Full firmware (first time)
esptool.py --chip esp32c3 --port COM3 write_flash --secure 0x0000 WLED_SP530E_Full_Latest.bin

# Individual components (advanced)
esptool.py --chip esp32c3 --port COM3 write_flash --secure \
  0x0000 Bootloader.bin \
  0x8000 Partitions.bin \
  0x10000 App.bin
```

### ESP Flash Download Tool
1. Load `WLED_SP530E_Full_Latest.bin` at address `0x0000`
2. Set chip to ESP32-C3
3. Flash

---

**No more hunting through artifacts! Everything you need is right here.** 🎯

<!-- Test commit for workflow trigger: main branch -->
