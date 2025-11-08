#include "wled.h"
#include "fcn_declare.h"
#include "wled_ethernet.h"


#ifdef WLED_USE_ETHERNET
// The following six pins are neither configurable nor
// can they be re-assigned through IOMUX / GPIO matrix.
// See https://docs.espressif.com/projects/esp-idf/en/latest/esp32/hw-reference/esp32/get-started-ethernet-kit-v1.1.html#ip101gri-phy-interface
const managed_pin_type esp32_nonconfigurable_ethernet_pins[WLED_ETH_RSVD_PINS_COUNT] = {
    { 21, true  }, // RMII EMAC TX EN  == When high, clocks the data on TXD0 and TXD1 to transmitter
    { 19, true  }, // RMII EMAC TXD0   == First bit of transmitted data
    { 22, true  }, // RMII EMAC TXD1   == Second bit of transmitted data
    { 25, false }, // RMII EMAC RXD0   == First bit of received data
    { 26, false }, // RMII EMAC RXD1   == Second bit of received data
    { 27, true  }, // RMII EMAC CRS_DV == Carrier Sense and RX Data Valid
};

const ethernet_settings ethernetBoards[] = {
  // None
  {
  },

  // WT32-EHT01
  // Please note, from my testing only these pins work for LED outputs:
  //   IO2, IO4, IO12, IO14, IO15
  // These pins do not appear to work from my testing:
  //   IO35, IO36, IO39
  {
    1,                    // eth_address,
    16,                   // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO0_IN    // eth_clk_mode
  },

  // ESP32-POE
  {
     0,                   // eth_address,
    12,                   // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT  // eth_clk_mode
  },

   // WESP32
  {
    0,			              // eth_address,
    -1,			              // eth_power,
    16,			              // eth_mdc,
    17,			              // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO0_IN	  // eth_clk_mode
  },

  // QuinLed-ESP32-Ethernet
  {
    0,			              // eth_address,
    5,			              // eth_power,
    23,			              // eth_mdc,
    18,			              // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT	// eth_clk_mode
  },

  // TwilightLord-ESP32 Ethernet Shield
  {
    0,			              // eth_address,
    5,			              // eth_power,
    23,			              // eth_mdc,
    18,			              // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT	// eth_clk_mode
  },

  // ESP3DEUXQuattro
  {
    1,                    // eth_address,
    -1,                   // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT  // eth_clk_mode
  },

  // ESP32-ETHERNET-KIT-VE
  {
    0,                    // eth_address,
    5,                    // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_IP101,        // eth_type,
    ETH_CLOCK_GPIO0_IN    // eth_clk_mode
  },

  // QuinLed-Dig-Octa Brainboard-32-8L and LilyGO-T-ETH-POE
  {
    0,			              // eth_address,
    -1,			              // eth_power,
    23,			              // eth_mdc,
    18,			              // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT	// eth_clk_mode
  },

  // ABC! WLED Controller V43 + Ethernet Shield & compatible
  {
    1,                    // eth_address, 
    5,                    // eth_power, 
    23,                   // eth_mdc, 
    33,                   // eth_mdio, 
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT	// eth_clk_mode
  },

  // Serg74-ESP32 Ethernet Shield
  {
    1,                    // eth_address,
    5,                    // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO17_OUT  // eth_clk_mode
  },

  // ESP32-POE-WROVER
  {
    0,                    // eth_address,
    12,                   // eth_power,
    23,                   // eth_mdc,
    18,                   // eth_mdio,
    ETH_PHY_LAN8720,      // eth_type,
    ETH_CLOCK_GPIO0_OUT   // eth_clk_mode
  },
  
  // LILYGO T-POE Pro
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
  // https://github.com/Xinyuan-LilyGO/LilyGO-T-ETH-Series/blob/master/schematic/T-POE-PRO.pdf
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
  {
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    0,			              // eth_address,
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    5,			              // eth_power,
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    23,			              // eth_mdc,
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    18,			              // eth_mdio,
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    ETH_PHY_LAN8720,      // eth_type,
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode
  },

  // ESP32-S3Dev-W5500
  // Generic ESP32-S3 development board with W5500 SPI Ethernet
  {
    0,			              // eth_address (not used for SPI),
    -1,			              // eth_power (W5500 reset handled separately),
    -1,			              // eth_mdc (not used for SPI),
    -1,			              // eth_mdio (not used for SPI),
    ETH_PHY_LAN8720,      // eth_type (placeholder, W5500 is SPI-based),
    ETH_CLOCK_GPIO0_OUT	// eth_clk_mode (not used for SPI)
  }
};
#endif


//by https://github.com/tzapu/WiFiManager/blob/master/WiFiManager.cpp
int getSignalQuality(int rssi)
{
    int quality = 0;

    if (rssi <= -100)
    {
        quality = 0;
    }
    else if (rssi >= -50)
    {
        quality = 100;
    }
    else
    {
        quality = 2 * (rssi + 100);
    }
    return quality;
}


//handle Ethernet connection event
void WiFiEvent(WiFiEvent_t event)
{
  switch (event) {
#if defined(ARDUINO_ARCH_ESP32) && defined(WLED_USE_ETHERNET)
    case SYSTEM_EVENT_ETH_START:
      DEBUG_PRINTLN(F("ETH Started"));
      break;
    case SYSTEM_EVENT_ETH_CONNECTED:
      {
      DEBUG_PRINTLN(F("ETH Connected"));
      if (!apActive) {
        WiFi.disconnect(true);
      }
      if (multiWiFi[0].staticIP != (uint32_t)0x00000000 && multiWiFi[0].staticGW != (uint32_t)0x00000000) {
        ETH.config(multiWiFi[0].staticIP, multiWiFi[0].staticGW, multiWiFi[0].staticSN, dnsAddress);
      } else {
        ETH.config(INADDR_NONE, INADDR_NONE, INADDR_NONE);
      }
      // convert the "serverDescription" into a valid DNS hostname (alphanumeric)
      char hostname[64];
      prepareHostname(hostname);
      ETH.setHostname(hostname);
      showWelcomePage = false;
      break;
      }
    case SYSTEM_EVENT_ETH_DISCONNECTED:
      DEBUG_PRINTLN(F("ETH Disconnected"));
      // This doesn't really affect ethernet per se,
      // as it's only configured once.  Rather, it
      // may be necessary to reconnect the WiFi when
      // ethernet disconnects, as a way to provide
      // alternative access to the device.
      forceReconnect = true;
      break;
#endif
    default:
      DEBUG_PRINTF_P(PSTR("Network event: %d\n"), (int)event);
      break;
  }
}


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
