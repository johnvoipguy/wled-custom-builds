# SP530E legacy hard tasks (old branch archive)

This page is for legacy SP530E branch workflows and one-off hacking tasks that do not belong in the main branch flow.

## When to use this page

Use this only if you are intentionally reproducing old branch behavior or recovering old SP530E setups.

- Old branch naming and package conventions
- Archived package-apply workflow
- Historical/manual flashing paths from older automation

If you are doing normal current builds/releases, use [targets/sp530e/README.md](README.md) instead.

## Legacy references

- Archived SP530E package flow:
  - https://github.com/johnvoipguy/wled-sp530e-mods/tree/main/sp530e_config_package
- Local v0.15.4 notes in this repo:
  - [targets/sp530e/v0.15.4/notes.md](v0.15.4/notes.md)

## Physical hacking image set

These are the archived physical wiring/hacking examples previously referenced in project README docs:

- [images/Front_lights.jpg](../../images/Front_lights.jpg)
- [images/back_no_wiring.jpg](../../images/back_no_wiring.jpg)
- [images/back_wiring.jpg](../../images/back_wiring.jpg)
- [images/Back_wiring_2.jpg](../../images/Back_wiring_2.jpg)
- [images/uart_connection.jpg](../../images/uart_connection.jpg)

## Historical file naming you may still see

Some older release and build systems used names like:

- `WLED_SP530E_Full_Latest.bin`
- `WLED_SP530E_App_Latest.bin`

Current canonical naming in this repo is normalized as:

- `wled-<version>-sp530e-<publish_suffix>.full.bin`
- `wled-<version>-sp530e-<publish_suffix>.app.bin`

## Legacy first-time flash command (ESP32-C3)

If you are working with an older full image naming pattern:

```sh
esptool.py --chip esp32c3 write_flash 0x0000 WLED_SP530E_Full_Latest.bin
```

For current builds, use the normalized `.full.bin` filename from Releases.

## Legacy troubleshooting patterns

- OTA from very old baseline fails:
  - Perform a UART flash with a full image first, then retry OTA.
- Behavior mismatch after restoring old assets:
  - Confirm partition and usermod assumptions match the old target line.
- Mixed old/new assets in one workspace:
  - Start clean, then apply one path only (legacy or current), not both.

## Safety notes

- Legacy procedures are preserved for recoverability, not as the default pipeline.
- Keep modern main-branch build/release flow separate from old branch hacks.
