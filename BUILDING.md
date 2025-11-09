# 🔧 Building & Development Guide

Complete guide for developers who want to build, customize, or contribute to this project.

---

## 📋 Table of Contents

- [Development Environment Setup](#-development-environment-setup)
- [Project Structure](#-project-structure)
- [Build System](#-build-system)
- [Development Workflow](#-development-workflow)
- [Customizing for Other Boards](#-customizing-for-other-boards)
- [Testing](#-testing)
- [Debugging](#-debugging)
- [Release Process](#-release-process)

---

## 🛠️ Development Environment Setup

### Required Tools

1. **Node.js 20+** (for web UI build)
   ```bash
   node --version  # Should be >= 20.0.0
   ```
   Install from [nodejs.org](https://nodejs.org/) or use nvm:
   ```bash
   nvm install 20
   nvm use 20
   ```

2. **Python 3.8+** (for PlatformIO)
   ```bash
   python3 --version
   ```

3. **PlatformIO Core** (build system)
   ```bash
   pip install -r requirements.txt
   ```

4. **Git** (version control)
   ```bash
   git --version
   ```

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/johnvoipguy/wled-custom-builds.git
cd wled-custom-builds
git checkout waveshare-esp32s3-eth-v15.1

# Install Node dependencies (fast, ~5 seconds)
npm ci

# Verify PlatformIO installation
pio --version
```

### VS Code Setup (Recommended)

1. Install [VS Code](https://code.visualstudio.com/)
2. Install extensions:
   - **PlatformIO IDE** (required)
   - **C/C++** (Microsoft, recommended)
   - **ESLint** (for web UI development)

3. Open the project folder:
   ```bash
   code .
   ```

---

## 📁 Project Structure

```
wled-waveshare-esp32s3-eth/
├── .github/              # GitHub Actions CI/CD
├── build_output/         # Build artifacts
│   └── release/         # Release binaries
├── platformio.ini       # PlatformIO build configuration ⭐
├── wled00/              # Main firmware source
│   ├── data/           # Web UI source files
│   │   ├── index.htm   # Main UI page
│   │   ├── settings_wifi.htm  # Network settings
│   │   └── *.js/*.css  # Web assets
│   ├── network.cpp     # W5500 integration ⭐
│   ├── wled.h          # Main header
│   └── src/
│       └── dependencies/
│           └── network/
│               └── Network.cpp  # Network abstraction ⭐
├── tools/               # Build scripts
│   └── cdata.js        # Web UI compiler
├── package.json         # Node.js dependencies
└── requirements.txt     # Python dependencies
```

### Key Files for W5500 Support

- **`platformio.ini`** - Environment `esp32s3_waveshare_eth` configuration
- **`wled00/network.cpp`** - `initW5500Ethernet()` function and board config
- **`wled00/src/dependencies/network/Network.cpp`** - Network priority handling
- **`wled00/data/settings_wifi.htm`** - Ethernet type dropdown (option 13)
- **`wled00/const.h`** - `WLED_NUM_ETH_TYPES` constant
- **`wled00/wled.h`** - Function declarations

---

## 🏗️ Build System

### Build Phases

WLED uses a two-phase build:

#### Phase 1: Web UI Build (`npm run build`)
- **Input**: HTML/CSS/JS files in `wled00/data/`
- **Process**: Minification and compression via `tools/cdata.js`
- **Output**: C++ headers in `wled00/html_*.h`
- **Duration**: ~3 seconds
- **CRITICAL**: Must run before firmware build!

#### Phase 2: Firmware Compilation (`pio run`)
- **Input**: C++ source + generated headers
- **Process**: Compilation, linking, partitions
- **Output**: 
  - `bootloader.bin` (15KB)
  - `partitions.bin` (3KB)
  - `firmware.bin` (1.4MB)
- **Duration**: 30-60 seconds (first build ~15 minutes for dependencies)

### Build Commands

```bash
# Full clean build (recommended for releases)
npm run build && pio run -e esp32s3_waveshare_eth

# Quick rebuild (if only C++ changed, skip web UI)
pio run -e esp32s3_waveshare_eth

# Clean everything
pio run -e esp32s3_waveshare_eth --target clean

# Force web UI rebuild
npm run build -- --force

# Build and flash
pio run -e esp32s3_waveshare_eth --target upload

# Build, flash, and monitor
pio run -e esp32s3_waveshare_eth --target upload --target monitor
```

### Creating Release Binaries

```bash
# Build the firmware
npm run build
pio run -e esp32s3_waveshare_eth

# App-only binary (already created by PlatformIO)
# Output: build_output/release/WLED_0.15.1_Waveshare_S3_ETH.bin

# Create FULL combined binary (bootloader + partitions + app)
esptool merge-bin \
  -o build_output/release/WLED_0.15.1_Waveshare_S3_ETH_FULL.bin \
  --flash-mode qio --flash-freq 80m --flash-size 16MB \
  0x0 .pio/build/esp32s3_waveshare_eth/bootloader.bin \
  0x8000 .pio/build/esp32s3_waveshare_eth/partitions.bin \
  0x10000 .pio/build/esp32s3_waveshare_eth/firmware.bin
```

---

## 🔄 Development Workflow

### Making Changes to Web UI

```bash
# 1. Edit files in wled00/data/
nano wled00/data/settings_wifi.htm

# 2. Rebuild web UI
npm run build

# 3. Build and flash firmware
pio run -e esp32s3_waveshare_eth --target upload

# 4. Monitor serial output
pio device monitor -b 115200
```

### Making Changes to Firmware

```bash
# 1. Edit C++ files
nano wled00/network.cpp

# 2. Build (web UI rebuild not needed if only C++ changed)
pio run -e esp32s3_waveshare_eth

# 3. Flash
pio run -e esp32s3_waveshare_eth --target upload

# 4. Monitor
pio device monitor -b 115200
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-awesome-feature

# Make changes, test thoroughly
# ... edit files ...
npm run build
pio run -e esp32s3_waveshare_eth
# ... test ...

# Commit changes
git add -A
git commit -m "Add awesome feature: description"

# Push to GitHub
git push origin feature/my-awesome-feature

# Create Pull Request on GitHub
```

---

## 🎨 Customizing for Other Boards

Want to adapt this for a different W5500 board? Here's how:

### 1. Create New Environment in `platformio.ini`

```ini
[env:myboard_w5500]
extends = esp32s3  ; or esp32, esp32c3, etc.
board = esp32-s3-devkitc-1  ; Change to your board
build_flags = 
    ${esp32s3.build_flags}
    -D WLED_RELEASE_NAME=\"MyBoard_ETH\"
    
    ; W5500 Pin Configuration - CHANGE THESE!
    -D WLED_USE_W5500
    -D W5500_CS_PIN=5      ; Your CS pin
    -D W5500_MOSI_PIN=23   ; Your MOSI pin
    -D W5500_MISO_PIN=19   ; Your MISO pin
    -D W5500_SCLK_PIN=18   ; Your SCLK pin
    -D W5500_RST_PIN=26    ; Your RST pin
    -D W5500_INT_PIN=34    ; Your INT pin
    
    ; LED and other pins
    -D LEDPIN=2            ; Your LED data pin
    -D DATA_PINS=2
    -D BTNPIN=0
    -D RLYPIN=-1
    -D IRPIN=-1

lib_deps =
    ${esp32s3.lib_deps}
    https://github.com/arduino-libraries/Ethernet.git

board_build.partitions = tools/WLED_ESP32_8MB.csv  ; Adjust for your flash size
```

### 2. Add Board Configuration to `wled00/network.cpp`

Find the `ethernetBoards` array (around line 130) and add:

```cpp
  // MyBoard W5500
  // Description of your board
  {
    0,                    // eth_address (not used for SPI)
    -1,                   // eth_power (W5500 reset handled separately)
    -1,                   // eth_mdc (not used for SPI)
    -1,                   // eth_mdio (not used for SPI)
    ETH_PHY_LAN8720,      // eth_type (placeholder for W5500)
    ETH_CLOCK_GPIO0_OUT   // eth_clk_mode (not used for SPI)
  // https://link-to-your-board-schematic
  },
```

### 3. Update `wled00/const.h`

Increment the board count:

```cpp
#define WLED_NUM_ETH_TYPES 15  // Was 14, now 15 for your board
```

### 4. Add Dropdown Option in `wled00/data/settings_wifi.htm`

Find the Ethernet type dropdown (around line 100) and add:

```html
<option value="14">MyBoard W5500</option>
```

### 5. Build and Test

```bash
npm run build
pio run -e myboard_w5500
pio run -e myboard_w5500 --target upload
```

---

## 🧪 Testing

### Automated Tests

```bash
# Run build system tests (validates web UI compilation)
npm test

# Takes ~40 seconds, verifies HTML generation
```

### Manual Testing Checklist

After building firmware:

- [ ] Ethernet connects and gets DHCP IP
- [ ] Web interface loads at `http://<IP>`
- [ ] LEDs light up and respond to controls
- [ ] Effects work properly
- [ ] Settings save and persist after reboot
- [ ] WiFi fallback works when Ethernet disconnected
- [ ] OTA updates work
- [ ] Serial output shows no errors

### Test Ethernet Detection

```bash
# Monitor serial during boot
pio device monitor -b 115200

# Look for these messages:
# "W5500 Ethernet initialized"
# "W5500 link: UP"
# "Ethernet connected"
# "Got IP: 192.168.x.x"
```

---

## 🐛 Debugging

### Serial Debugging

```bash
# Basic monitoring
pio device monitor -b 115200

# With filtering (less noisy)
pio device monitor -b 115200 --filter direct

# Decode exceptions
pio device monitor -b 115200 --filter esp32_exception_decoder
```

### Enable Debug Output

Add to `platformio.ini` build_flags:

```ini
build_flags = 
    ; ... existing flags ...
    -D WLED_DEBUG           ; General debug output
    -D DEBUGPRINT           ; Extra verbose
    -D CORE_DEBUG_LEVEL=3   ; ESP32 core debug level
```

### Common Issues

**Build fails with "html_*.h not found"**
- Solution: Run `npm run build` first

**Ethernet not initializing**
- Check pin definitions in `platformio.ini`
- Verify W5500 wiring matches your board
- Check serial output for SPI errors

**Out of memory during build**
- Solution: Disable some features in build_flags
- Or use a board with more flash

---

## 📦 Release Process

### Version Management

1. Update version in `platformio.ini`:
   ```ini
   -D WLED_RELEASE_NAME=\"Waveshare_S3_ETH_v1.0.1\"
   ```

2. Tag the release:
   ```bash
   git tag -a v1.0.1 -m "Release v1.0.1: Description"
   git push origin v1.0.1
   ```

### Creating Release Artifacts

```bash
# Clean build
pio run -e esp32s3_waveshare_eth --target clean
npm run build
pio run -e esp32s3_waveshare_eth

# Create FULL binary
esptool merge-bin \
  -o WLED_v1.0.1_Waveshare_S3_ETH_FULL.bin \
  --flash-mode qio --flash-freq 80m --flash-size 16MB \
  0x0 .pio/build/esp32s3_waveshare_eth/bootloader.bin \
  0x8000 .pio/build/esp32s3_waveshare_eth/partitions.bin \
  0x10000 .pio/build/esp32s3_waveshare_eth/firmware.bin

# Copy app-only binary
cp build_output/release/WLED_0.15.1_Waveshare_S3_ETH.bin \
   WLED_v1.0.1_Waveshare_S3_ETH.bin

# Create checksums
sha256sum WLED_v1.0.1_*.bin > checksums.txt
```

### GitHub Release

1. Go to GitHub repository → Releases → New Release
2. Select the tag you created
3. Upload both `.bin` files and `checksums.txt`
4. Write release notes describing changes
5. Publish release

---

## 📚 Additional Resources

### WLED Development

- [WLED Development Guide](https://kno.wled.ge/advanced/custom-features/)
- [WLED API Documentation](https://kno.wled.ge/interfaces/http-api/)
- [PlatformIO Documentation](https://docs.platformio.org/)

### ESP32-S3 Resources

- [ESP32-S3 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32-s3_technical_reference_manual_en.pdf)
- [Arduino ESP32 Documentation](https://docs.espressif.com/projects/arduino-esp32/en/latest/)
- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/latest/)

### W5500 Resources

- [W5500 Datasheet](https://www.wiznet.io/product-item/w5500/)
- [Arduino Ethernet Library](https://github.com/arduino-libraries/Ethernet)
- [W5500 Application Notes](https://www.wiznet.io/document/#w5500)

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

Quick tips:
- Always test your changes thoroughly
- Follow existing code style
- Update documentation when adding features
- Run `npm test` before committing
- Write clear commit messages

---

## 💬 Getting Help

- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join [WLED Discord](https://discord.gg/wled) #dev channel
- **Forum**: [WLED Discourse Forum](https://wled.discourse.group/)

---

<div align="center">

**Happy Building! 🚀**

[⬆ Back to Main README](README.md)

</div>
