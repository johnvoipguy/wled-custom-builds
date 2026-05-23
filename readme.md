# WLED Custom Builds

This repository is a neutral, multi-target home for custom WLED build metadata on top of upstream `main`.

## Repository layering model

| Layer | Location | Role |
|---|---|---|
| **Base / upstream defaults** | repo root (`platformio.ini`, workflows, scripts) | Generic WLED build foundation — not target-specific |
| **Target source of truth** | `targets/<target>/shared/` | Canonical home for all target-specific metadata, config, partitions, usermods |
| **Version-specific deltas** | `targets/<target>/v15/`, `targets/<target>/v16/` | Only what differs per WLED version line; reference `shared/`, do not duplicate it |
| **Preserved firmware assets** | `targets/<target>/v<N>/assets/legacy/` | Intentionally retained validated historical firmware binaries; not generated outputs |

> **Rule:** If a file is target-specific, it belongs under `targets/<target>/shared/`, not in the root.
> The root `platformio.ini` and scripts are the generic base layer; target directories are the source of truth.
> Preserved historical firmware lives under `targets/<target>/v<N>/assets/legacy/` — not in top-level `build_output/` or `builds/`.

## Target highlights

- **Seeed Xiao ESP32S3:** canonical PlatformIO env and build metadata live in
  `targets/seeed-xiao-esp32s3/shared/platformio.env.ini`. Version notes under
  `v15/` and `v16/` are deltas only. **All Seeed preserved firmware is v16** —
  validated historical binaries live in `targets/seeed-xiao-esp32s3/v16/assets/legacy/`.
- **Waveshare ESP32-S3-ETH:** W5500 SPI Ethernet support is documented in
  `targets/waveshare-esp32s3-eth/shared/platformio.env.ini` and
  `targets/waveshare-esp32s3-eth/v15/notes.md`. **v15 is the active Waveshare line**.
- **SP530E:** salvaged partition CSV and LED status usermods live in
  `targets/sp530e/shared/`.

## Repository direction

- `main` is the canonical branch.
- The layout is target/version oriented under `targets/`.
- Legacy branch-per-version and clone-per-version workflows are deprecated.
- Generated artifacts, nested repositories, `.pio`, and build outputs must stay out of git.
- **Exception:** intentionally preserved, validated historical firmware binaries may be committed
  under `targets/<target>/v<N>/assets/legacy/` with a clear README explaining their provenance.
  These represent tested/regression-validated firmware and are kept to avoid losing that work.

## Directory layout

```text
manifests/
  build-matrix.yml          ← target/version/env mapping
scripts/
  apply-target.sh           ← stage target assets (usermods, partitions, env fragment) into a workspace
  build-target.sh           ← read target manifest, resolve WLED base, apply target, run pio build
  legacy/                   ← old scripts preserved as reference only
wled_bases/
  <wled_ref>/               ← optional local WLED base checkouts used before upstream fallback
targets/
  sp530e/
    shared/                 ← source of truth: partitions, usermods, build.default.json
    v15/  v16/              ← version deltas / notes (+ build.json manifest)
  seeed-xiao-esp32s3/
    shared/
      platformio.env.ini    ← canonical Seeed PlatformIO env definition
      build.default.json    ← fallback manifest when targets/<target>/<version>/build.json is missing
      build.example.json    ← complete manifest example (environment, wled_ref, optional wled_repo)
      partitions/           ← partition table notes (uses tools/WLED_ESP32_8MB.csv)
      usermods/             ← enabled usermod notes
    v15/                    ← version delta (no Seeed-specific content yet)
    v16/
      notes.md              ← v16 delta notes
      assets/
        legacy/             ← preserved validated historical firmware binaries
          README.md
          *.bin
  waveshare-esp32s3-eth/
    shared/
      platformio.env.ini    ← canonical Waveshare PlatformIO env definition
      build.default.json    ← fallback manifest when targets/<target>/<version>/build.json is missing
      build.example.json    ← complete manifest example (environment, wled_ref, optional wled_repo)
    v15/
      notes.md              ← v15 active-line delta notes
      assets/
        README.md           ← no preserved legacy firmware currently tracked
    v16/                    ← future placeholder only
platformio.ini              ← generic WLED base (root = upstream defaults, not target-specific)
```

## Starter workflow

1. Describe target/version combinations in `manifests/build-matrix.yml`.
2. Keep target-specific config and assets under `targets/<target>/shared/`.
3. Set `targets/<target>/<version>/build.json` (`environment`, `wled_ref`, optional `wled_repo`), or rely on `targets/<target>/shared/build.default.json` as fallback.
4. Use `scripts/apply-target.sh` and `scripts/build-target.sh` to stage and build.

```sh
# Stage Seeed assets into an existing WLED workspace (overlay mode: v16/ dir exists)
scripts/apply-target.sh --target seeed-xiao-esp32s3 --version v16 --workspace /path/to/wled

# Stage + build in a temporary workspace (overlay mode)
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16

# Build against a specific upstream WLED ref (WLED-ref mode: 'main' dir does not exist)
scripts/build-target.sh --target seeed-xiao-esp32s3 --version main

# Force a specific environment when needed
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16 --environment seeed_xiao_esp32s3v2
```

### Version semantics

`scripts/build-target.sh` interprets `--version <v>` in one of two ways:

| Condition | Mode | Behavior |
|---|---|---|
| `targets/<target>/<v>/` **exists** | **Overlay** | `<v>` is a version key. Assets from `shared/` and `<v>/` are applied. Manifest: `<v>/build.json` → `shared/build.default.json`. |
| `targets/<target>/<v>/` **does not exist** | **WLED-ref** | `<v>` is treated as the WLED git ref (branch or tag). Only `shared/` assets are applied. Manifest: `shared/build.default.json` (optional). |

In WLED-ref mode, the WLED ref defaults to `--version` unless `--wled-ref` is explicitly passed.

### Environment resolution

The build environment is resolved in this order (first non-empty value wins):

1. `--environment <env>` CLI flag
2. `environment` field in the resolved manifest (`build.json` or `build.default.json`)
3. `[env:<name>]` sections parsed from `targets/<target>/shared/platformio.env.ini`

When parsing the env fragment:
- **Exactly one env found**: used automatically.
- **Multiple envs found (local)**: all environments are built sequentially; per-env logs written as `build.<env>.log`.
- **Multiple envs found (CI)**: build fails with an error. Specify `--environment` or set `environment` in the manifest.

To always use a known single environment, pass `--environment` explicitly or set it in the manifest.

`scripts/build-target.sh` prefers a local base checkout at `wled_bases/<wled_ref>/`.
If it does not exist, it fetches upstream (`wled_repo`, default `https://github.com/Aircoookie/WLED.git`) at `wled_ref` in a temporary workspace.
When version-specific `targets/<target>/<version>/build.json` is missing, it automatically falls back to `targets/<target>/shared/build.default.json`.
`scripts/apply-target.sh` also ensures copied `platformio.env.ini` is included from workspace `platformio.ini` via `[platformio] extra_configs` so custom env names are recognized in upstream workspaces.
Each run writes dated logs/metadata under `logs/<target>/<version>/<YYYYMMDD-HHMM>/`:
- `apply.log` — target asset staging output
- `npm.log` — `npm ci` + `npm run build` output
- `build.<env>.log` — PlatformIO build output (one file per built environment)
- `meta.json` — build metadata (target, version, wled_ref, environment(s), version_mode, etc.)

## Legacy scripts

Legacy shell scripts live in `scripts/legacy/` as reference material only.
They are preserved to document the old repo-sprawl workflow but are not supported.

## Notes on salvaged assets

The SP530E target carries salvaged assets into `targets/sp530e/shared/`:

- custom partition CSV: `WLED_ESP32C3_4MB_audioreactive.csv`
- usermods: `boot_status_led`, `wifi_status_led`

## Notes on preserved firmware assets

The Seeed Xiao ESP32S3 target carries preserved historical validated firmware binaries in
`targets/seeed-xiao-esp32s3/v16/assets/legacy/`. These represent the result of substantial
manual testing and regression work and are intentionally retained in the repository.

See [`targets/seeed-xiao-esp32s3/v16/assets/legacy/README.md`](targets/seeed-xiao-esp32s3/v16/assets/legacy/README.md)
for the full inventory, provenance, and flashing instructions.

> **Convention:** Only deliberately retained, validated firmware belongs in
> `targets/<target>/v<N>/assets/legacy/`. Do not commit routine build outputs there.
> Use GitHub Releases for distributing new firmware builds.

See the per-target `notes.md` files for guidance on where additional target-specific work should land.
