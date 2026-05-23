#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build-target.sh --target <target> --version <version> [--environment <pio-env>] [--wled-ref <ref>] [--wled-repo <repo-url>] [--workspace <path>] [--plan]

By default this reads targets/<target>/<version>/build.json, prepares a temporary workspace
under /tmp from a local wled_bases/<wled_ref>/ checkout when available (or clones upstream),
applies target assets, and prints or runs the standard WLED build commands.
USAGE
}

die() {
  echo "Error: $*" >&2
  exit 1
}

json_get_value() {
  local json_file=$1
  local json_key=$2
  python - "$json_file" "$json_key" <<'PY'
import json
import sys

json_file, json_key = sys.argv[1], sys.argv[2]
with open(json_file, encoding="utf-8") as fp:
  data = json.load(fp)

value = data.get(json_key, "")
if value is None:
  value = ""
if not isinstance(value, str):
  value = str(value)

print(value)
PY
}

set_github_output() {
  local key=$1
  local value=$2
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf '%s=%s\n' "$key" "$value" >> "$GITHUB_OUTPUT"
  fi
}

target=
version=
environment=
workspace=
wled_ref=
wled_repo=
plan_only=false
keep_workspace=false
base_source=
script_dir=
repo_root=
manifest_path=
log_dir=
apply_log=
build_log=
meta_json=
repo_sha=
timestamp_utc=

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
    --wled-ref)
      wled_ref=${2:-}
      shift 2
      ;;
    --wled-repo)
      wled_repo=${2:-}
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

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
manifest_path="$repo_root/targets/$target/$version/build.json"
default_wled_repo="https://github.com/Aircoookie/WLED.git"
timestamp_utc=$(date -u +%Y%m%d-%H%M)
log_dir="$repo_root/logs/$target/$version/$timestamp_utc"
apply_log="$log_dir/apply.log"
build_log="$log_dir/build.log"
meta_json="$log_dir/meta.json"
repo_sha=$(git -C "$repo_root" rev-parse HEAD)

mkdir -p "$log_dir"

[ -f "$manifest_path" ] || die "missing manifest: $manifest_path"

if [ -z "$environment" ]; then
  environment=$(json_get_value "$manifest_path" "environment")
fi
[ -n "$environment" ] || die "manifest '$manifest_path' must define non-empty 'environment' (or pass --environment)"

if [ -z "$wled_ref" ]; then
  wled_ref=$(json_get_value "$manifest_path" "wled_ref")
fi
[ -n "$wled_ref" ] || die "manifest '$manifest_path' must define non-empty 'wled_ref' (or pass --wled-ref)"

if [ -z "$wled_repo" ]; then
  wled_repo=$(json_get_value "$manifest_path" "wled_repo")
fi
if [ -z "$wled_repo" ]; then
  wled_repo=$default_wled_repo
fi

cleanup() {
  local status=$?
  if [ -n "$workspace" ] && [ "$keep_workspace" = false ] && [[ "$workspace" == /tmp/* ]]; then
    rm -rf "$workspace"
  fi
  exit "$status"
}
trap cleanup EXIT

if [ -z "$workspace" ]; then
  workspace=$(mktemp -d "/tmp/wled-target-${target}-${version}-XXXXXX")
fi

mkdir -p "$workspace"
shopt -s dotglob nullglob
workspace_entries=("$workspace"/*)
if [ "${#workspace_entries[@]}" -gt 0 ]; then
  rm -rf "${workspace_entries[@]}"
fi
shopt -u dotglob nullglob

if [ -d "$repo_root/wled_bases/$wled_ref" ]; then
  base_source=local
  cp -a "$repo_root/wled_bases/$wled_ref/." "$workspace/"
else
  base_source=upstream
  git -C "$workspace" init || die "failed to initialize workspace git repository at $workspace"
  git -C "$workspace" remote add origin "$wled_repo" || die "failed to add remote '$wled_repo' in workspace $workspace"
  git -C "$workspace" fetch --depth 1 origin "$wled_ref" || die "failed to fetch WLED ref '$wled_ref' from '$wled_repo'"
  git -C "$workspace" checkout --detach FETCH_HEAD || die "failed to checkout fetched WLED ref '$wled_ref'"
fi

[ -d "$workspace/wled00" ] || die "workspace '$workspace' does not look like a WLED checkout after base setup"

apply_args=(
  --target "$target"
  --version "$version"
  --workspace "$workspace"
)

if [ "$plan_only" = true ]; then
  apply_args+=(--plan)
fi

set_github_output "target" "$target"
set_github_output "version" "$version"
set_github_output "environment" "$environment"
set_github_output "workspace" "$workspace"
set_github_output "build_dir" "$workspace/.pio/build/$environment"
set_github_output "wled_ref" "$wled_ref"
set_github_output "wled_repo" "$wled_repo"
set_github_output "base_source" "$base_source"
set_github_output "log_dir" "$log_dir"
set_github_output "apply_log" "$apply_log"
set_github_output "build_log" "$build_log"
set_github_output "meta_json" "$meta_json"

python - "$meta_json" "$target" "$version" "$wled_ref" "$base_source" "$environment" "$repo_sha" "$timestamp_utc" "$wled_repo" <<'PY'
import json
import sys

meta_path, target, tgt_version, wled_ref, base_source, environment, repo_sha, timestamp, wled_repo = sys.argv[1:]
payload = {
  "target": target,
  "tgtVersion": tgt_version,
  "wled_ref": wled_ref,
  "base_source": base_source,
  "environment": environment,
  "repo_sha": repo_sha,
  "timestamp": timestamp,
  "wled_repo": wled_repo,
}
with open(meta_path, "w", encoding="utf-8") as fp:
  json.dump(payload, fp, indent=2)
  fp.write("\n")
PY

printf 'Planned PlatformIO environment: %s\n' "$environment"
printf 'Planned WLED ref: %s (%s)\n' "$wled_ref" "$base_source"
printf 'Workspace: %s\n' "$workspace"

set +e
"$script_dir/apply-target.sh" "${apply_args[@]}" 2>&1 | tee "$apply_log"
apply_status=${PIPESTATUS[0]}
set -e
[ "$apply_status" -eq 0 ] || exit "$apply_status"

if [ "$plan_only" = true ]; then
  {
    echo "Plan only: would run 'npm ci', 'npm run build', and 'pio run -e $environment' in $workspace"
  } | tee "$build_log"
  exit 0
fi

set +e
(
  cd "$workspace"
  npm ci
  npm run build
  pio run -e "$environment"
) 2>&1 | tee "$build_log"
build_status=${PIPESTATUS[0]}
set -e
[ "$build_status" -eq 0 ] || exit "$build_status"
