# SP530E v15

Starter notes for the SP530E 0.15.x line.

- Shared salvaged assets currently staged under `targets/sp530e/shared/`.
- Use `scripts/apply-target.sh` or `scripts/build-target.sh` instead of creating a new clone per version.

## Flashing (UART / first-time install)

The SP530E ships with Flash Encryption enabled (factory eFuse) and requires DIO flash mode.
Always use both `--encrypt` and `--flash-mode dio` when writing `.full.bin` over UART:

```sh
esptool.py --chip esp32c3 --flash-mode dio write_flash --encrypt 0x0000 wled-<version>-sp530e-<suffix>.full.bin
```

> **Note:** `--encrypt` is specific to the SP530E and must **not** be used with other board models.
