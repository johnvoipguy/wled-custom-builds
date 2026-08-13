# Vendored, patched copy

Source: `khoih-prog/Ethernet_Generic` v2.8.1 (PlatformIO registry).

Patched in `src/EthernetClient_Impl.h` (search `WLED patch`): the ESP32/ESP8266 branch of
`EthernetClient::connect(IPAddress, uint16_t)` called `IPAddress(0xFFFFFFFFul)`, which is
ambiguous against arduino-esp32 core 2.0.18's `IPAddress.h` (it added an `IPAddress(int)`
constructor alongside the pre-existing `IPAddress(uint32_t)`). Fixed with an explicit
`(uint32_t)` cast — no behavior change, just resolves the overload ambiguity.

No other changes. Re-verify this patch is still needed (or still sufficient) before bumping the
vendored version — check whether upstream `khoih-prog/Ethernet_Generic` has since fixed this
itself, and whether a newer arduino-esp32 core changes the ambiguity.

See `../../notes.md` for why this had to be vendored instead of pulled from the PlatformIO
registry directly (also: this library is h-only — see the ODR note there before including it
from a second `.cpp` file).
