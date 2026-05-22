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
  echo "  (include via extra_configs in platformio.ini if needed, or use as reference)"
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

echo "Applied target assets into $workspace"
if [ -f "$version_dir/notes.md" ]; then
  echo "Notes: $version_dir/notes.md"
fi
