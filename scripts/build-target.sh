#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build-target.sh --target <target> --version <version> [--environment <pio-env>] [--wled-ref <ref>] [--wled-repo <repo-url>] [--workspace <path>] [--plan]

Version semantics:
  - If targets/<target>/<version>/ exists, <version> is treated as an overlay version key.
    Manifest resolution: targets/<target>/<version>/build.json -> targets/<target>/shared/build.default.json.
  - If targets/<target>/<version>/ does NOT exist, <version> is treated as the WLED ref (branch/tag).
    Only targets/<target>/shared/ assets are applied. Manifest: targets/<target>/shared/build.default.json (optional).

Environment resolution order (first non-empty wins):
  1. --environment CLI flag
  2. 'environment' field in manifest
  3. [env:<name>] sections in targets/<target>/shared/platformio.env.ini
     - Exactly one env found: use it automatically.
     - Multiple envs found: build all (local only). CI disallows multi-env without explicit selection.

Pass --environment or set 'environment' in the manifest to force a single environment.
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

is_ci() {
  [ "${GITHUB_ACTIONS:-}" = "true" ]
}

parse_envs_from_ini() {
  local ini_file=$1
  python - "$ini_file" <<'PY'
import re
import sys

ini_file = sys.argv[1]
try:
  with open(ini_file, encoding="utf-8") as fp:
    content = fp.read()
except OSError as exc:
  print(f"Error: cannot read {ini_file}: {exc}", file=sys.stderr)
  sys.exit(1)
envs = re.findall(r'^\[env:([^\]]+)\]', content, re.MULTILINE)
for e in envs:
  print(e)
PY
}

human_size_bytes() {
  local bytes=${1:-0}
  python - "$bytes" <<'PY'
import sys

size = int(sys.argv[1])
units = ["B", "KB", "MB", "GB"]
value = float(size)
unit = units[0]
for unit in units:
  if value < 1024 or unit == units[-1]:
    break
  value /= 1024
print(f"{value:.2f} {unit}" if unit != "B" else f"{int(value)} {unit}")
PY
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
version_manifest_path=
fallback_manifest_path=
manifest_fallback=false
version_is_overlay=
multi_env=false
log_dir=
apply_log=
build_log=
run_log=
summary_log=
meta_json=
repo_sha=
timestamp_utc=
output_dir=

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
version_manifest_path="$repo_root/targets/$target/$version/build.json"
fallback_manifest_path="$repo_root/targets/$target/shared/build.default.json"
default_wled_repo="https://github.com/Aircoookie/WLED.git"
timestamp_utc=$(date -u +%Y%m%d-%H%M%S)
log_dir="$repo_root/logs/$target/$version/$timestamp_utc"
run_log="$log_dir/run.log"
apply_log="$run_log"
build_log="$run_log"
summary_log="$log_dir/summary.txt"
meta_json="$log_dir/meta.json"
output_dir="$repo_root/outputs/$target/$version/$timestamp_utc"
repo_sha=$(git -C "$repo_root" rev-parse HEAD)

# Determine version mode: overlay (version dir exists) or WLED-ref (version dir absent)
if [ -d "$repo_root/targets/$target/$version" ]; then
  version_is_overlay=true
else
  version_is_overlay=false
fi

mkdir -p "$log_dir"
mkdir -p "$output_dir"

declare -a copied_artifacts=()
declare -A copied_artifact_seen=()

copy_artifact_file() {
  local source_file=$1
  local destination_dir=$2
  [ -f "$source_file" ] || return 1

  mkdir -p "$destination_dir"
  local destination_file="$destination_dir/$(basename "$source_file")"
  cp -f "$source_file" "$destination_file"

  local rel_path="${destination_file#"$output_dir"/}"
  if [ -z "${copied_artifact_seen[$rel_path]+x}" ]; then # first time this destination was copied
    local size_bytes
    size_bytes=$(wc -c < "$destination_file" | tr -d '[:space:]')
    copied_artifacts+=("$rel_path|$size_bytes")
    copied_artifact_seen["$rel_path"]=1
  fi
  return 0
}

copy_artifacts_for_env() {
  local env_name=$1
  local env_build_dir="$workspace/.pio/build/$env_name"
  local env_output_dir="$output_dir/$env_name"
  local release_output_dir="$output_dir/release"

  shopt -s nullglob
  local release_bins=("$workspace/build_output/release/"*.bin)
  local optional_bins=("$env_build_dir/"*.bin)
  local optional_uf2=("$env_build_dir/"*.uf2)
  shopt -u nullglob

  for file in "${release_bins[@]}"; do
    copy_artifact_file "$file" "$release_output_dir" || true
  done

  copy_artifact_file "$env_build_dir/firmware.bin" "$env_output_dir" || true
  copy_artifact_file "$env_build_dir/firmware.elf" "$env_output_dir" || true
  copy_artifact_file "$env_build_dir/firmware.map" "$env_output_dir" || true

  for file in "${optional_bins[@]}"; do
    copy_artifact_file "$file" "$env_output_dir" || true
  done
  for file in "${optional_uf2[@]}"; do
    copy_artifact_file "$file" "$env_output_dir" || true
  done
}

# Manifest resolution
if [ "$version_is_overlay" = true ]; then
  if [ -f "$version_manifest_path" ]; then
    manifest_path="$version_manifest_path"
  elif [ -f "$fallback_manifest_path" ]; then
    manifest_path="$fallback_manifest_path"
    manifest_fallback=true
  else
    die "missing manifest: $version_manifest_path (fallback also missing: $fallback_manifest_path)"
  fi
else
  # WLED-ref mode: version directory does not exist; use shared default manifest if available
  if [ -f "$fallback_manifest_path" ]; then
    manifest_path="$fallback_manifest_path"
  fi
  # manifest_path may remain empty in WLED-ref mode; env and wled_ref are inferred below
fi

# Environment resolution: CLI flag -> manifest -> shared env fragment
resolved_envs=()
if [ -n "$environment" ]; then
  resolved_envs=("$environment")
else
  _env_from_manifest=
  if [ -n "$manifest_path" ]; then
    _env_from_manifest=$(json_get_value "$manifest_path" "environment")
  fi
  if [ -n "$_env_from_manifest" ]; then
    resolved_envs=("$_env_from_manifest")
  else
    _shared_ini="$repo_root/targets/$target/shared/platformio.env.ini"
    _parsed_envs=()
    if [ -f "$_shared_ini" ]; then
      mapfile -t _parsed_envs < <(parse_envs_from_ini "$_shared_ini")
    fi
    if [ "${#_parsed_envs[@]}" -eq 1 ]; then
      resolved_envs=("${_parsed_envs[0]}")
    elif [ "${#_parsed_envs[@]}" -gt 1 ]; then
      if is_ci; then
        die "Multiple environments found in $_shared_ini (${_parsed_envs[*]}) but no single environment specified. CI requires a single environment. Pass --environment or set 'environment' in the manifest."
      else
        resolved_envs=("${_parsed_envs[@]}")
      fi
    fi
  fi
fi
[ "${#resolved_envs[@]}" -gt 0 ] || die "Could not determine build environment for target '$target'. Pass --environment or set 'environment' in the manifest or targets/$target/shared/platformio.env.ini."

environment=${resolved_envs[0]}
if [ "${#resolved_envs[@]}" -gt 1 ]; then
  multi_env=true
fi

# build_log points to first (or only) env log; per-env logs written as build.<env>.log
build_log="$log_dir/build.${environment}.log"

# wled_ref resolution: CLI flag -> version (WLED-ref mode) or manifest (overlay mode)
if [ -z "$wled_ref" ]; then
  if [ "$version_is_overlay" = false ]; then
    # WLED-ref mode: version argument IS the WLED ref
    wled_ref=$version
  elif [ -n "$manifest_path" ]; then
    # Overlay mode: read wled_ref from manifest
    wled_ref=$(json_get_value "$manifest_path" "wled_ref")
  fi
fi
[ -n "$wled_ref" ] || die "Could not determine wled_ref for target '$target'. Pass --wled-ref or ensure the manifest defines 'wled_ref'."

# wled_repo resolution: CLI flag -> manifest -> default
if [ -z "$wled_repo" ]; then
  if [ -n "$manifest_path" ]; then
    wled_repo=$(json_get_value "$manifest_path" "wled_repo")
  fi
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

if [ "$version_is_overlay" = false ]; then
  apply_args+=(--no-version-overlay)
fi

if [ "$plan_only" = true ]; then
  apply_args+=(--plan)
fi

set_github_output "target" "$target"
set_github_output "version" "$version"
set_github_output "environment" "$environment"
set_github_output "workspace" "$workspace"
if [ "$multi_env" = false ]; then
  set_github_output "build_dir" "$workspace/.pio/build/$environment"
fi
set_github_output "wled_ref" "$wled_ref"
set_github_output "wled_repo" "$wled_repo"
set_github_output "base_source" "$base_source"
set_github_output "log_dir" "$log_dir"
set_github_output "run_log" "$run_log"
set_github_output "apply_log" "$apply_log"
set_github_output "build_log" "$build_log"
set_github_output "summary_log" "$summary_log"
set_github_output "meta_json" "$meta_json"
set_github_output "output_dir" "$output_dir"
set_github_output "manifest_path" "$manifest_path"
set_github_output "manifest_fallback" "$manifest_fallback"

envs_joined=$(printf '%s,' "${resolved_envs[@]}")
envs_joined=${envs_joined%,}

python - "$meta_json" "$target" "$version" "$wled_ref" "$base_source" "$environment" "$repo_sha" "$timestamp_utc" "$wled_repo" "$manifest_path" "$manifest_fallback" "$version_is_overlay" "$envs_joined" "$run_log" "$summary_log" "$output_dir" <<'PY'
import json
import os
import sys

(meta_path, target, tgt_version, wled_ref, base_source, environment,
 repo_sha, timestamp, wled_repo, manifest_path, manifest_fallback,
 version_is_overlay, envs_joined, run_log, summary_log, output_dir) = sys.argv[1:]
environments = [e for e in envs_joined.split(',') if e]
payload = {
  "target": target,
  "tgtVersion": tgt_version,
  "wled_ref": wled_ref,
  "base_source": base_source,
  "environment": environment,
  "environments": environments,
  "multi_env": len(environments) > 1,
  "version_mode": "overlay" if version_is_overlay.lower() == "true" else "wled-ref",
  "repo_sha": repo_sha,
  "timestamp": timestamp,
  "wled_repo": wled_repo,
  "manifest_path": manifest_path,
  "manifest_fallback": manifest_fallback.lower() == "true",
  "log_dir": os.path.dirname(run_log),
  "run_log": run_log,
  "summary_log": summary_log,
  "output_dir": output_dir,
}
with open(meta_path, "w", encoding="utf-8") as fp:
  json.dump(payload, fp, indent=2)
  fp.write("\n")
PY

printf 'Version mode: %s\n' "$( [ "$version_is_overlay" = true ] && echo "overlay" || echo "wled-ref" )"
printf 'Planned PlatformIO environment(s): %s\n' "${resolved_envs[*]}"
printf 'Planned WLED ref: %s (%s)\n' "$wled_ref" "$base_source"
printf 'Planned manifest: %s' "${manifest_path:-<none>}"
if [ "$manifest_fallback" = true ]; then
  printf ' (fallback)'
fi
printf '\n'
printf 'Workspace: %s\n' "$workspace"

: > "$run_log"
exec > >(tee -a "$run_log") 2>&1

echo "==== WLED custom build run ===="
echo "Target: $target"
echo "Version: $version"
echo "Version mode: $( [ "$version_is_overlay" = true ] && echo "overlay" || echo "wled-ref" )"
echo "WLED ref: $wled_ref"
echo "WLED source: $base_source ($wled_repo)"
echo "Workspace: $workspace"
echo "Log directory: $log_dir"
echo "Run log: $run_log"
echo "Output directory: $output_dir"
echo

"$script_dir/apply-target.sh" "${apply_args[@]}"

if [ "$plan_only" = true ]; then
  for _env in "${resolved_envs[@]}"; do
    echo "Plan only: would run 'npm ci', 'npm run build', and 'pio run -e $_env' in $workspace"
  done
  exit 0
fi

(
  cd "$workspace"
  npm ci
  npm run build
)

for _env in "${resolved_envs[@]}"; do
  (
    cd "$workspace"
    pio run -e "$_env"
  )
  copy_artifacts_for_env "$_env"
done

{
  echo "Build summary"
  echo "============="
  echo "target: $target"
  echo "version: $version"
  echo "version_mode: $( [ "$version_is_overlay" = true ] && echo "overlay" || echo "wled-ref" )"
  echo "wled_ref: $wled_ref"
  echo "base_source: $base_source"
  echo "wled_repo: $wled_repo"
  echo "environments: ${resolved_envs[*]}"
  echo "log_dir: $log_dir"
  echo "run_log: $run_log"
  echo "meta_json: $meta_json"
  echo "output_dir: $output_dir"
  echo "artifacts:"
  if [ "${#copied_artifacts[@]}" -eq 0 ]; then
    echo "  - (none copied)"
  else
    for artifact_entry in "${copied_artifacts[@]}"; do
      artifact_file=${artifact_entry%%|*}
      artifact_size=${artifact_entry##*|}
      echo "  - $artifact_file ($(human_size_bytes "$artifact_size"), $artifact_size bytes)"
    done
  fi
} | tee "$summary_log"

latest_dir="$repo_root/logs/$target/$version/latest"
rm -rf "$latest_dir"
mkdir -p "$latest_dir"
cp -a "$log_dir/." "$latest_dir/"

echo
echo "Build outputs saved to: $output_dir"
echo "Latest logs copied to: $latest_dir"
echo "Run complete."
