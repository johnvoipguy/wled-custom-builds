#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/apply-target.sh --target <target> --version <version> --workspace <path> [--no-version-overlay] [--plan]

Copies tracked target assets from targets/<target>/shared and targets/<target>/<version>
into an existing WLED workspace without creating clone farms.

Recognized asset subdirectories under shared/ and <version>/ (all optional):
  usermods/  -> copied into workspace/usermods
  partitions/-> copied into workspace/tools
  lib/       -> copied into workspace/lib (vendored/patched PlatformIO libraries)
  patches/*.patch -> applied against the workspace tree (core wled00/ changes that
                      don't fit the usermod/partition/env-fragment overlay shapes).
                      Applied shared/ first, then <version>/, each in filename sort order.

--no-version-overlay  Skip copying version-specific assets (only shared/ assets are applied).
                      Used when <version> is a WLED ref rather than a version overlay directory.
USAGE
}

die() {
  echo "Error: $*" >&2
  exit 1
}

copy_tree() {
  local source_dir=$1
  local dest_dir=$2

  [ -d "$source_dir" ] || return 0
  mkdir -p "$dest_dir"

  find "$source_dir" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' ! -name 'notes.md' -print0 | while IFS= read -r -d '' entry; do
    cp -a "$entry" "$dest_dir/"
  done
}

copy_env_fragment() {
  local source_file=$1
  local dest_dir=$2

  if [ ! -f "$source_file" ]; then
    echo "No env fragment found at $source_file (skipped)"
    return 0
  fi
  cp "$source_file" "$dest_dir/platformio.env.ini"
  echo "Copied env fragment: $source_file -> $dest_dir/platformio.env.ini"
}

apply_patches() {
  local patches_dir=$1
  local workspace_dir=$2

  [ -d "$patches_dir" ] || return 0

  local patch_files=()
  local patch_file
  for patch_file in "$patches_dir"/*.patch; do
    [ -f "$patch_file" ] || continue
    patch_files+=("$patch_file")
  done
  [ "${#patch_files[@]}" -gt 0 ] || return 0

  # Pre-check every patch before applying any of them, so a drifted upstream reports every
  # broken patch in one pass instead of dying on the first and hiding the rest.
  if [ -d "$workspace_dir/.git" ]; then
    local failed=()
    for patch_file in "${patch_files[@]}"; do
      if git -C "$workspace_dir" apply --check "$patch_file" 2>/dev/null; then
        echo "Patch check OK: $patch_file"
      else
        echo "Patch check FAILED: $patch_file"
        failed+=("$patch_file")
      fi
    done
    if [ "${#failed[@]}" -gt 0 ]; then
      echo "The following patches do not apply cleanly against this workspace:" >&2
      for patch_file in "${failed[@]}"; do
        echo "  - $patch_file" >&2
      done
      die "${#failed[@]} patch(es) failed pre-check in $patches_dir (see above)"
    fi
  fi

  for patch_file in "${patch_files[@]}"; do
    echo "Applying patch: $patch_file"
    if [ -d "$workspace_dir/.git" ]; then
      git -C "$workspace_dir" apply --whitespace=nowarn "$patch_file" \
        || die "failed to apply patch (git apply): $patch_file"
    elif command -v patch >/dev/null 2>&1; then
      patch -p1 -d "$workspace_dir" --forward < "$patch_file" \
        || die "failed to apply patch (patch -p1): $patch_file"
    else
      die "cannot apply patch $patch_file: workspace is not a git repo and 'patch' is not available"
    fi
  done
}

is_env_fragment_file() {
  local source_file=$1

  python - "$source_file" <<'PY'
import re
import sys

path = sys.argv[1]
section_re = re.compile(r'^\s*\[([^\]]+)\]\s*$')
sections = []

with open(path, encoding="utf-8") as fp:
    for line in fp:
        match = section_re.match(line)
        if match:
            sections.append(match.group(1).strip())

has_env_section = any(section.startswith("env:") for section in sections)
has_non_env_section = any(not section.startswith("env:") for section in sections)

sys.exit(0 if has_env_section and not has_non_env_section else 1)
PY
}

resolve_env_fragment_in_dir() {
  local base_dir=$1
  local candidates=(
    "$base_dir/platformio.env.ini"
    "$base_dir/platformio-env.ini"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [ -f "$candidate" ]; then
      if is_env_fragment_file "$candidate"; then
        printf '%s\n' "$candidate"
        return 0
      fi
      echo "Skipping non-fragment PlatformIO config: $candidate" >&2
    fi
  done
  return 1
}

ensure_env_fragment_extra_config() {
  local workspace_ini=$1
  local env_fragment=$2

  if [ ! -f "$workspace_ini" ]; then
    echo "No workspace platformio.ini found at $workspace_ini (skipped extra_configs update)"
    return 0
  fi

  python - "$workspace_ini" "$env_fragment" <<'PY'
import re
import sys

ini_path, env_fragment = sys.argv[1], sys.argv[2]

with open(ini_path, encoding="utf-8") as fp:
  lines = fp.read().splitlines(keepends=True)

section_re = re.compile(r'^\s*\[([^\]]+)\]\s*$')
key_re = re.compile(r'^\s*([A-Za-z0-9_.-]+)\s*=')

def section_bounds(target_name):
  start = None
  for idx, line in enumerate(lines):
    match = section_re.match(line)
    if not match:
      continue
    section_name = match.group(1).strip().lower()
    if section_name == target_name:
      start = idx
      break
  if start is None:
    return None
  end = len(lines)
  for idx in range(start + 1, len(lines)):
    if section_re.match(lines[idx]):
      end = idx
      break
  return start, end

def extra_configs_block(start, end):
  for idx in range(start + 1, end):
    key_match = key_re.match(lines[idx])
    if not key_match:
      continue
    if key_match.group(1).strip().lower() != "extra_configs":
      continue
    block_end = idx + 1
    while block_end < end:
      line = lines[block_end]
      if not line.strip():
        break
      if key_re.match(line):
        break
      if section_re.match(line):
        break
      if re.match(r'^\s+', line) or re.match(r'^\s*[;#]', line):
        block_end += 1
        continue
      break
    return idx, block_end
  return None

def parse_extra_config_values(block_start, block_end):
  values = []
  for idx in range(block_start, block_end):
    raw = lines[idx]
    if idx == block_start:
      raw = raw.split("=", 1)[1] if "=" in raw else ""
    raw = re.split(r"\s[;#]", raw, maxsplit=1)[0]
    for token in re.split(r"[,\s]+", raw.strip()):
      if token:
        values.append(token)
  return values

bounds = section_bounds("platformio")
changed = False
message = ""

if bounds is None:
  if lines and not lines[-1].endswith("\n"):
    lines[-1] += "\n"
  if lines and lines[-1].strip():
    lines.append("\n")
  lines.extend([
    "[platformio]\n",
    "extra_configs =\n",
    f"  {env_fragment}\n",
  ])
  changed = True
  message = "Added [platformio] section with extra_configs include for platformio.env.ini"
else:
  section_start, section_end = bounds
  block = extra_configs_block(section_start, section_end)
  if block is None:
    lines[section_end:section_end] = [
      "extra_configs =\n",
      f"  {env_fragment}\n",
    ]
    changed = True
    message = "Added platformio.env.ini to [platformio] extra_configs"
  else:
    block_start, block_end = block
    existing_values = parse_extra_config_values(block_start, block_end)
    if env_fragment in existing_values:
      message = "platformio.env.ini already present in [platformio] extra_configs"
    else:
      lines.insert(block_end, f"  {env_fragment}\n")
      changed = True
      message = "Appended platformio.env.ini to [platformio] extra_configs"

if changed:
  with open(ini_path, "w", encoding="utf-8") as fp:
    fp.write("".join(lines))

print(message)
PY
}

target=
version=
workspace=
plan_only=false
no_version_overlay=false

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      target=${2:-}
      shift 2
      ;;
    --version)
      version=${2:-}
      shift 2
      ;;
    --workspace)
      workspace=${2:-}
      shift 2
      ;;
    --plan|--dry-run)
      plan_only=true
      shift
      ;;
    --no-version-overlay)
      no_version_overlay=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[ -n "$target" ] || die "--target is required"
[ -n "$version" ] || die "--version is required"
[ -n "$workspace" ] || die "--workspace is required"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
base_dir="$repo_root/targets/$target"
shared_dir="$base_dir/shared"
version_dir="$base_dir/$version"

[ -d "$base_dir" ] || die "target '$target' does not exist under $repo_root/targets"
if [ "$no_version_overlay" = false ]; then
  [ -d "$version_dir" ] || die "version '$version' does not exist for target '$target'"
fi
[ -d "$workspace" ] || die "workspace '$workspace' does not exist"
[ -d "$workspace/wled00" ] || die "workspace '$workspace' does not look like a WLED checkout"

printf 'Target: %s\nVersion: %s\nWorkspace: %s\n' "$target" "$version" "$workspace"

for required in usermods tools; do
  mkdir -p "$workspace/$required"
done

if [ "$plan_only" = true ]; then
  echo "Plan only: no files copied."
  if [ "$no_version_overlay" = true ]; then
    find "$shared_dir" -mindepth 1 -maxdepth 2 ! -name '.gitkeep' | sort
  else
    find "$shared_dir" "$version_dir" -mindepth 1 -maxdepth 2 ! -name '.gitkeep' | sort
  fi
  exit 0
fi

copy_tree "$shared_dir/usermods" "$workspace/usermods"
copy_tree "$shared_dir/partitions" "$workspace/tools"
copy_tree "$shared_dir/lib" "$workspace/lib"
apply_patches "$shared_dir/patches" "$workspace"
if [ "$no_version_overlay" = false ]; then
  copy_tree "$version_dir/usermods" "$workspace/usermods"
  copy_tree "$version_dir/partitions" "$workspace/tools"
  copy_tree "$version_dir/lib" "$workspace/lib"
  apply_patches "$version_dir/patches" "$workspace"
fi

selected_env_fragment=
if [ "$no_version_overlay" = false ]; then
  selected_env_fragment=$(resolve_env_fragment_in_dir "$version_dir" || true)
fi
if [ -z "$selected_env_fragment" ]; then
  selected_env_fragment=$(resolve_env_fragment_in_dir "$shared_dir" || true)
fi
if [ -n "$selected_env_fragment" ]; then
  copy_env_fragment "$selected_env_fragment" "$workspace"
fi

ensure_env_fragment_extra_config "$workspace/platformio.ini" "platformio.env.ini"

echo "Applied target assets into $workspace"
if [ "$no_version_overlay" = false ] && [ -f "$version_dir/notes.md" ]; then
  echo "Notes: $version_dir/notes.md"
fi
