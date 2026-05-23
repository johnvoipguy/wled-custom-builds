#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/apply-target.sh --target <target> --version <version> --workspace <path> [--plan]

Copies tracked target assets from targets/<target>/shared and targets/<target>/<version>
into an existing WLED workspace without creating clone farms.
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
[ -d "$version_dir" ] || die "version '$version' does not exist for target '$target'"
[ -d "$workspace" ] || die "workspace '$workspace' does not exist"
[ -d "$workspace/wled00" ] || die "workspace '$workspace' does not look like a WLED checkout"

printf 'Target: %s\nVersion: %s\nWorkspace: %s\n' "$target" "$version" "$workspace"

for required in usermods tools; do
  mkdir -p "$workspace/$required"
done

if [ "$plan_only" = true ]; then
  echo "Plan only: no files copied."
  find "$shared_dir" "$version_dir" -mindepth 1 -maxdepth 2 ! -name '.gitkeep' | sort
  exit 0
fi

copy_tree "$shared_dir/usermods" "$workspace/usermods"
copy_tree "$shared_dir/partitions" "$workspace/tools"
copy_tree "$version_dir/usermods" "$workspace/usermods"
copy_tree "$version_dir/partitions" "$workspace/tools"
copy_env_fragment "$shared_dir/platformio.env.ini" "$workspace"
ensure_env_fragment_extra_config "$workspace/platformio.ini" "platformio.env.ini"

echo "Applied target assets into $workspace"
if [ -f "$version_dir/notes.md" ]; then
  echo "Notes: $version_dir/notes.md"
fi
