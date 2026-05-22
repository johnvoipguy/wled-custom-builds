#!/bin/bash

# Script to set up ESP32-S3 W5500 support in the dedicated directory
ESP32S3_DIR="/workspace/wled-esp32s3-w5500"
CURRENT_DIR="/workspace/wled-main-sp530e"

echo "Setting up ESP32-S3 W5500 support in $ESP32S3_DIR"

# Switch to the ESP32-S3 directory
cd "$ESP32S3_DIR"

# Check current branch
echo "Current branch: $(git branch --show-current)"

# Add ESP32-S3 W5500 environment to platformio.ini
echo "Adding esp32s3_w5500 environment to platformio.ini..."
cat >> platformio.ini << 'EOF'

[env:esp32s3_w5500]
;; Generic ESP32-S3 development board with W5500 SPI Ethernet
;; Works with various ESP32-S3 boards: Waveshare POE, LilyGO T-ETH-Lite, etc.
;; 16MB Flash, 8MB PSRAM, W5500 SPI Ethernet
extends = esp32s3
platform = ${esp32s3.platform}
board = esp32-s3-devkitc-1
board_build.arduino.memory_type = qio_opi     ;; 8MB PSRAM support
upload_speed = 921600
custom_usermods = audioreactive
build_unflags = ${common.build_unflags}
build_flags = ${common.build_flags} ${esp32s3.build_flags} -D WLED_RELEASE_NAME=\"ESP32S3_W5500\"
  -D CONFIG_LITTLEFS_FOR_IDF_3_2 -D WLED_WATCHDOG_TIMEOUT=0
  -D ARDUINO_USB_CDC_ON_BOOT=0  ;; serial-to-USB chip (not USB-OTG)
  -D ARDUINO_USB_MODE=1
  -DBOARD_HAS_PSRAM
  ;; W5500 SPI Ethernet Configuration
  -D WLED_USE_W5500
  -D W5500_CS_PIN=10
  -D W5500_MOSI_PIN=11
  -D W5500_MISO_PIN=13
  -D W5500_SCLK_PIN=12
  -D W5500_RST_PIN=14
  -D W5500_INT_PIN=21
  ;; Standard WLED pins  
  -D LEDPIN=48        ;; Onboard RGB LED (typical for ESP32-S3)
  -D DATA_PINS=48     ;; LED strip data pin
  -D BTNPIN=0         ;; Boot button
  -D RLYPIN=-1        ;; No relay pin
  -D IRPIN=-1         ;; No IR receiver
lib_deps = ${esp32s3.lib_deps}
  ;; W5500 Ethernet library - better option than UIPEthernet
  https://github.com/arduino-libraries/Ethernet.git
board_build.partitions = ${esp32.large_partitions}  ;; 8MB partitions
board_upload.flash_size = 16MB
board_upload.maximum_size = 16777216
board_build.f_flash = 80000000L
board_build.flash_mode = qio
monitor_filters = esp32_exception_decoder
EOF

# Update const.h to increment WLED_NUM_ETH_TYPES
echo "Updating WLED_NUM_ETH_TYPES in const.h..."
sed -i 's/#define WLED_NUM_ETH_TYPES        13/#define WLED_NUM_ETH_TYPES        14/' wled00/const.h

# Add ESP32-S3Dev-W5500 to ethernet dropdown in settings_wifi.htm
echo "Adding ESP32-S3Dev-W5500 to web interface..."
sed -i '/LILYGO T-POE Pro<\/option>/a\
				<option value="13">ESP32-S3Dev-W5500</option>' wled00/data/settings_wifi.htm

# Add W5500 board configuration to network.cpp
echo "Adding W5500 board configuration to network.cpp..."

# Create a backup and add the configuration
cp wled00/network.cpp wled00/network.cpp.backup

# Add the new ethernet board entry
sed -i '/LILYGO T-POE Pro/,/ETH_CLOCK_GPIO0_OUT/a\
  },\
\
  // ESP32-S3Dev-W5500\
  // Generic ESP32-S3 development board with W5500 SPI Ethernet\
  {\
    0,			              // eth_address (not used for SPI),\
    -1,			              // eth_power (W5500 reset handled separately),\
    -1,			              // eth_mdc (not used for SPI),\
    -1,			              // eth_mdio (not used for SPI),\
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),\
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)' wled00/network.cpp

# Add W5500 initialization function and include
echo "Adding W5500 initialization function..."
cat >> wled00/network.cpp << 'EOF'

#ifdef WLED_USE_W5500
#include <Ethernet.h>
#include <SPI.h>

bool WLED::initW5500Ethernet() {
  static bool successfullyConfiguredW5500 = false;
  
  if (successfullyConfiguredW5500) {
    return false;
  }
  
  DEBUG_PRINTLN(F("initW5500: Starting W5500 SPI Ethernet initialization"));
  
  // Allocate W5500 SPI pins
  managed_pin_type w5500Pins[6] = {
    { W5500_CS_PIN,   true },  // CS pin (output)
    { W5500_MOSI_PIN, true },  // MOSI pin (output)  
    { W5500_MISO_PIN, false }, // MISO pin (input)
    { W5500_SCLK_PIN, true },  // SCLK pin (output)
    { W5500_RST_PIN,  true },  // Reset pin (output)
    { W5500_INT_PIN,  false }  // Interrupt pin (input, optional)
  };
  
  if (!PinManager::allocateMultiplePins(w5500Pins, 6, PinOwner::Ethernet)) {
    DEBUG_PRINTLN(F("initW5500: Failed to allocate W5500 pins"));
    return false;
  }
  
  // Reset W5500
  pinMode(W5500_RST_PIN, OUTPUT);
  digitalWrite(W5500_RST_PIN, LOW);
  delay(100);
  digitalWrite(W5500_RST_PIN, HIGH);
  delay(200);
  
  // Initialize SPI
  SPI.begin(W5500_SCLK_PIN, W5500_MISO_PIN, W5500_MOSI_PIN, W5500_CS_PIN);
  
  // Start Ethernet with DHCP
  if (Ethernet.begin(nullptr) == 0) {
    DEBUG_PRINTLN(F("initW5500: DHCP failed, trying static IP"));
    
    // Fall back to static IP if available
    if (multiWiFi[0].staticIP != (uint32_t)0x00000000 && multiWiFi[0].staticGW != (uint32_t)0x00000000) {
      Ethernet.begin(nullptr, multiWiFi[0].staticIP, multiWiFi[0].staticGW, multiWiFi[0].staticSN);
    } else {
      DEBUG_PRINTLN(F("initW5500: No static IP configured, using default"));
      IPAddress ip(192, 168, 1, 100);
      IPAddress gateway(192, 168, 1, 1); 
      IPAddress subnet(255, 255, 255, 0);
      Ethernet.begin(nullptr, ip, gateway, subnet);
    }
  }
  
  // Give it time to connect
  delay(1500);
  
  if (Ethernet.localIP() == INADDR_NONE) {
    DEBUG_PRINTLN(F("initW5500: Failed to get IP address"));
    // Deallocate pins on failure
    for (auto& pin : w5500Pins) {
      PinManager::deallocatePin(pin.pin, PinOwner::Ethernet);
    }
    return false;
  }
  
  successfullyConfiguredW5500 = true;
  DEBUG_PRINTF_P(PSTR("initW5500: *** W5500 successfully configured! IP: %d.%d.%d.%d ***\n"), 
    Ethernet.localIP()[0], Ethernet.localIP()[1], 
    Ethernet.localIP()[2], Ethernet.localIP()[3]);
    
  return true;
}
#endif
EOF

# Add function declaration to wled.h
echo "Adding W5500 function declaration to wled.h..."
sed -i '/bool initEthernet(); \/\/ result is informational/a\
#ifdef WLED_USE_W5500\
  bool initW5500Ethernet(); // W5500 SPI ethernet initialization\
#endif' wled00/wled.h

# Add W5500 check to wled.cpp initEthernet function
echo "Adding W5500 check to initEthernet function..."
sed -i '/DEBUG_PRINTF_P(PSTR("initE: Attempting ETH config: %d\\n"), ethernetType);/a\
\
#ifdef WLED_USE_W5500\
  // Check if this is an ESP32-S3Dev-W5500 board (ethernetType == 13)\
  if (ethernetType == 13) {\
    return initW5500Ethernet();\
  }\
#endif' wled00/wled.cpp

# Update Network.cpp to support W5500
echo "Updating Network.cpp for W5500 support..."
cat > wled00/src/dependencies/network/Network.cpp << 'EOF'
#include "Network.h"
#ifdef WLED_USE_W5500
#include <Ethernet.h>
#endif

IPAddress NetworkClass::localIP()
{
  IPAddress localIP;
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  localIP = Ethernet.localIP();
  if (localIP[0] != 0) {
    return localIP;
  }
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  localIP = ETH.localIP();
  if (localIP[0] != 0) {
    return localIP;
  }
#endif
  localIP = WiFi.localIP();
  if (localIP[0] != 0) {
    return localIP;
  }

  return INADDR_NONE;
}

IPAddress NetworkClass::subnetMask()
{
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  if (Ethernet.localIP()[0] != 0) {
    return Ethernet.subnetMask();
  }
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  if (ETH.localIP()[0] != 0) {
    return ETH.subnetMask();
  }
#endif
  if (WiFi.localIP()[0] != 0) {
    return WiFi.subnetMask();
  }
  return IPAddress(255, 255, 255, 0);
}

IPAddress NetworkClass::gatewayIP()
{
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  if (Ethernet.localIP()[0] != 0) {
      return Ethernet.gatewayIP();
  }
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  if (ETH.localIP()[0] != 0) {
      return ETH.gatewayIP();
  }
#endif
  if (WiFi.localIP()[0] != 0) {
      return WiFi.gatewayIP();
  }
  return INADDR_NONE;
}

void NetworkClass::localMAC(uint8_t* MAC)
{
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  if (Ethernet.localIP()[0] != 0) {
    // W5500 MAC address handling
    byte mac[6];
    Ethernet.MACAddress(mac);
    memcpy(MAC, mac, 6);
    // Check if we got a valid MAC
    for (uint8_t i = 0; i < 6; i++) {
      if (MAC[i] != 0x00) {
        return;
      }
    }
  }
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  // ETH.macAddress(MAC); // Does not work because of missing ETHClass:: in ETH.ccp

  // Start work around
  String macString = ETH.macAddress();
  char macChar[18];
  char * octetEnd = macChar;

  strlcpy(macChar, macString.c_str(), 18);

  for (uint8_t i = 0; i < 6; i++) {
    MAC[i] = (uint8_t)strtol(octetEnd, &octetEnd, 16);
    octetEnd++;
  }
  // End work around

  for (uint8_t i = 0; i < 6; i++) {
    if (MAC[i] != 0x00) {
      return;
    }
  }
#endif
  WiFi.macAddress(MAC);
  return;
}

bool NetworkClass::isConnected()
{
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  if (Ethernet.localIP()[0] != 0) {
    return true; // W5500 is connected
  }
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  return (WiFi.localIP()[0] != 0 && WiFi.status() == WL_CONNECTED) || ETH.localIP()[0] != 0;
#else
  return (WiFi.localIP()[0] != 0 && WiFi.status() == WL_CONNECTED);
#endif
}

bool NetworkClass::isEthernet()
{
#ifdef WLED_USE_W5500
  // Check W5500 first (SPI ethernet)
  return (Ethernet.localIP()[0] != 0);
#endif
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
  return (ETH.localIP()[0] != 0);
#endif
  return false;
}

EOF

echo "ESP32-S3 W5500 setup complete!"
echo ""
echo "Changes made:"
echo "1. Added esp32s3_w5500 environment to platformio.ini"
echo "2. Updated WLED_NUM_ETH_TYPES in const.h"
echo "3. Added ESP32-S3Dev-W5500 to web interface dropdown"
echo "4. Added W5500 board configuration to network.cpp"
echo "5. Added initW5500Ethernet() function"
echo "6. Updated Network.cpp for W5500 support"
echo ""
echo "To build: pio run -e esp32s3_w5500"