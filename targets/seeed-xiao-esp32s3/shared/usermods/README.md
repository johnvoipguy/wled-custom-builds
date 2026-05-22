# Seeed Xiao ESP32S3 — Usermods

The following usermods are enabled for the Seeed Xiao ESP32S3 target.
They are activated by name via `custom_usermods` in `platformio.env.ini`:

```ini
custom_usermods = Internal_Temperature sht wizlights AHT10
```

## Enabled usermods

| Usermod name | Description |
|---|---|
| `Internal_Temperature` | Reads the ESP32-S3 internal die temperature sensor (`USERMOD_INTERNAL_TEMPERATURE`) |
| `sht` | SHT series (SHT30/SHT31/SHT40) temperature and humidity sensor support |
| `wizlights` | Philips WiZ smart light integration (`USERMOD_WIZLIGHTS`) |
| `AHT10` | AHT10/AHT20 temperature and humidity sensor support |

## Source location

These are standard WLED usermods whose source lives in the `usermods/` directory at the
repository root. No Seeed-specific usermod source code is currently required.

## If you need a Seeed-specific usermod

Place `.cpp` / `.h` source and a `library.json` in a subdirectory here, then add the
subdirectory name to `custom_usermods` in `platformio.env.ini`.

Example:
```
targets/seeed-xiao-esp32s3/shared/usermods/my_seeed_mod/
  my_seeed_mod.cpp
  my_seeed_mod.h
  library.json
```
