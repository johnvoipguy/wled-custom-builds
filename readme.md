<p align="center">
  <img src="/images/wled_logo_akemi.png">
  <a href="https://github.com/Aircoookie/WLED/releases"><img src="https://img.shields.io/github/release/Aircoookie/WLED.svg?style=flat-square"></a>
  <a href="https://raw.githubusercontent.com/Aircoookie/WLED/master/LICENSE"><img src="https://img.shields.io/github/license/Aircoookie/wled?color=blue&style=flat-square"></a>
  <a href="https://wled.discourse.group"><img src="https://img.shields.io/discourse/topics?colorB=blue&label=forum&server=https%3A%2F%2Fwled.discourse.group%2F&style=flat-square"></a>
  <a href="https://discord.gg/QAh7wJHrRM"><img src="https://img.shields.io/discord/473448917040758787.svg?colorB=blue&label=discord&style=flat-square"></a>
  <a href="https://kno.wled.ge"><img src="https://img.shields.io/badge/quick_start-wiki-blue.svg?style=flat-square"></a>
  <a href="https://github.com/Aircoookie/WLED-App"><img src="https://img.shields.io/badge/app-wled-blue.svg?style=flat-square"></a>
  <a href="https://gitpod.io/#https://github.com/Aircoookie/WLED"><img src="https://img.shields.io/badge/Gitpod-ready--to--code-blue?style=flat-square&logo=gitpod"></a>

  </p>

# Welcome to my project WLED! ✨

A fast and feature-rich implementation of an ESP8266/ESP32 webserver to control NeoPixel (WS2812B, WS2811, SK6812) LEDs or also SPI based chipsets like the WS2801 and APA102!

## 🔌 Waveshare ESP32-S3-ETH Custom Build

This is a custom WLED build for the **Waveshare ESP32-S3-ETH** board with W5500 Ethernet support.

### Hardware Configuration
- **Board**: Waveshare ESP32-S3-ETH (ESP32-S3, 16MB Flash, 8MB PSRAM)
- **Ethernet**: W5500 SPI Ethernet (pins: MISO=12, MOSI=11, SCLK=13, CS=14, RST=9, INT=10)
- **LED Outputs**: 8 channels configured (GPIO 48, 47, 38, 39, 40, 41, 42, 2)
- **Features**: MQTT, AudioReactive usermod enabled

### Flashing Instructions

#### Using esptool.py (Command Line)
1. Download the firmware from `build_output/release/`
2. Flash using esptool.py:

```bash
# Full flash (includes bootloader, partitions, and firmware)
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 921600 \
  write_flash 0x0 WLED_*_FULL.bin

# Or OTA update only (if already running WLED)
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 921600 \
  write_flash 0x10000 WLED_*_OTA.bin
```

Replace `/dev/ttyACM0` with your serial port (Windows: `COM3`, `COM4`, etc.)

### Network Configuration

**IMPORTANT**: This build uses a dual-interface setup due to AsyncTCP library limitations with W5500:

#### Dual-Interface Operation
- **WiFi Interface (required)**: Provides web interface, WebSockets, and HTTP API
- **Ethernet Interface (optional)**: Provides UDP protocols (E1.31, Art-Net, DDP) for LED control

#### Initial Setup Procedure
1. **First boot** (without Ethernet cable):
   - Device creates AP: `WLED-ETH-Config` (open, no password)
   - Connect to AP and configure WiFi via web interface (http://4.3.2.1)
   - Save settings and reboot

2. **Subsequent boots** (with Ethernet cable connected):
   - Ethernet: Gets DHCP address (e.g., 192.168.50.239)
   - WiFi: Connects to configured SSID (e.g., 192.168.50.230)
   - Both interfaces active simultaneously

#### Interface Capabilities

**WiFi Interface** (.230 in example):
- ✅ Full web interface
- ✅ WebSockets for real-time updates
- ✅ HTTP/JSON API
- ✅ OTA updates
- ✅ All UDP protocols (E1.31, Art-Net, DDP)

**Ethernet Interface** (.239 in example):
- ✅ UDP protocols (E1.31, Art-Net, DDP) - **Best for LED streaming**
- ✅ MQTT
- ✅ Ping/ICMP
- ❌ Web interface (AsyncWebServer limitation)
- ❌ HTTP/JSON API
- ❌ WebSockets

#### Recommended Usage
- **Configure** via WiFi web interface (http://192.168.50.230)
- **Control LEDs** via Ethernet UDP protocols for low-latency, reliable streaming
- **Automatic failover**: If Ethernet disconnects, WiFi continues to work

### Technical Notes

The AsyncTCP library used by WLED's web server is hardcoded to use ESP32's LwIP TCP stack and cannot bind to the W5500's separate TCP stack. This requires keeping WiFi active to provide web interface functionality while Ethernet handles UDP-based LED control protocols.

For Ethernet-only operation, the entire web server would need to be replaced with ESP32's synchronous WebServer library, which is a substantial code change beyond the scope of this build.

## ⚙️ Features
- WS2812FX library with more than 100 special effects  
- FastLED noise effects and 50 palettes  
- Modern UI with color, effect and segment controls  
- Segments to set different effects and colors to user defined parts of the LED string  
- Settings page - configuration via the network  
- Access Point and station mode - automatic failsafe AP  
- Up to 10 LED outputs per instance
- Support for RGBW strips  
- Up to 250 user presets to save and load colors/effects easily, supports cycling through them.  
- Presets can be used to automatically execute API calls  
- Nightlight function (gradually dims down)  
- Full OTA software updateability (HTTP + ArduinoOTA), password protectable  
- Configurable analog clock (Cronixie, 7-segment and EleksTube IPS clock support via usermods) 
- Configurable Auto Brightness limit for safe operation  
- Filesystem-based config for easier backup of presets and settings  

## 💡 Supported light control interfaces
- WLED app for [Android](https://play.google.com/store/apps/details?id=com.aircoookie.WLED) and [iOS](https://apps.apple.com/us/app/wled/id1475695033)
- JSON and HTTP request APIs  
- MQTT   
- E1.31, Art-Net, DDP and TPM2.net
- [diyHue](https://github.com/diyhue/diyHue) (Wled is supported by diyHue, including Hue Sync Entertainment under udp. Thanks to [Gregory Mallios](https://github.com/gmallios))
- [Hyperion](https://github.com/hyperion-project/hyperion.ng)
- UDP realtime  
- Alexa voice control (including dimming and color)  
- Sync to Philips hue lights  
- Adalight (PC ambilight via serial) and TPM2  
- Sync color of multiple WLED devices (UDP notifier)  
- Infrared remotes (24-key RGB, receiver required)  
- Simple timers/schedules (time from NTP, timezones/DST supported)  

## 📲 Quick start guide and documentation

See the [documentation on our official site](https://kno.wled.ge)!

[On this page](https://kno.wled.ge/basics/tutorials/) you can find excellent tutorials and tools to help you get your new project up and running!

## 🖼️ User interface
<img src="/images/macbook-pro-space-gray-on-the-wooden-table.jpg" width="50%"><img src="/images/walking-with-iphone-x.jpg" width="50%">

## 💾 Compatible hardware

See [here](https://kno.wled.ge/basics/compatible-hardware)!

## ✌️ Other

Licensed under the EUPL v1.2 license  
Credits [here](https://kno.wled.ge/about/contributors/)!

Join the Discord server to discuss everything about WLED!

<a href="https://discord.gg/QAh7wJHrRM"><img src="https://discordapp.com/api/guilds/473448917040758787/widget.png?style=banner2" width="25%"></a>

Check out the WLED [Discourse forum](https://wled.discourse.group)!  

You can also send me mails to [dev.aircoookie@gmail.com](mailto:dev.aircoookie@gmail.com), but please, only do so if you want to talk to me privately.  

If WLED really brightens up your day, you can [![](https://img.shields.io/badge/send%20me%20a%20small%20gift-paypal-blue.svg?style=flat-square)](https://paypal.me/aircoookie)


*Disclaimer:*   

If you are prone to photosensitive epilepsy, we recommended you do **not** use this software.  
If you still want to try, don't use strobe, lighting or noise modes or high effect speed settings.

As per the EUPL license, I assume no liability for any damage to you or any other person or equipment.  

