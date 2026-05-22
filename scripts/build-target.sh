#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build-target.sh --target <target> --version <version> --environment <pio-env> [--workspace <path>] [--plan]

By default this prepares a temporary workspace under /tmp, applies target assets, and prints
or runs the standard WLED build commands without creating permanent clone farms.
USAGE
}

die() {
  echo "Error: $*" >&2
  exit 1
}

target=
version=
environment=
workspace=
plan_only=false
keep_workspace=false

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
    --environment)
      environment=${2:-}
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
    --keep-workspace)
      keep_workspace=true
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
[ -n "$environment" ] || die "--environment is required"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

cleanup() {
  if [ -n "$workspace" ] && [ "$keep_workspace" = false ] && [[ "$workspace" == /tmp/* ]]; then
    rm -rf "$workspace"
  fi
}
trap cleanup EXIT

if [ -z "$workspace" ]; then
  workspace=$(mktemp -d "/tmp/wled-target-${target}-${version}-XXXXXX")
  git -C "$repo_root" archive HEAD | tar -x -C "$workspace"
fi

[ -d "$workspace/wled00" ] || die "workspace '$workspace' does not look like a WLED checkout"
[ -f "$workspace/platformio.ini" ] || die "workspace '$workspace' does not look like a WLED checkout"

apply_args=(
  --target "$target"
  --version "$version"
  --workspace "$workspace"
)

if [ "$plan_only" = true ]; then
  apply_args+=(--plan)
fi

"$script_dir/apply-target.sh" "${apply_args[@]}"

printf 'Planned PlatformIO environment: %s\n' "$environment"
printf 'Workspace: %s\n' "$workspace"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    printf 'workspace=%s\n' "$workspace"
    printf 'environment=%s\n' "$environment"
  } >> "$GITHUB_OUTPUT"
fi

if [ "$plan_only" = true ]; then
  echo "Plan only: would run 'npm ci', 'npm run build', and 'pio run -e $environment' in $workspace"
  exit 0
fi

(
  cd "$workspace"
  npm ci
  npm run build
  pio run -e "$environment"
)
