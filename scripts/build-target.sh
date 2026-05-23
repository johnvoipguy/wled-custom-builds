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
with open(ini_file, encoding="utf-8") as fp:
  content = fp.read()
envs = re.findall(r'^\[env:([^\]]+)\]', content, re.MULTILINE)
for e in envs:
  print(e)
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
version_manifest_path="$repo_root/targets/$target/$version/build.json"
fallback_manifest_path="$repo_root/targets/$target/shared/build.default.json"
default_wled_repo="https://github.com/Aircoookie/WLED.git"
timestamp_utc=$(date -u +%Y%m%d-%H%M)
log_dir="$repo_root/logs/$target/$version/$timestamp_utc"
apply_log="$log_dir/apply.log"
meta_json="$log_dir/meta.json"
repo_sha=$(git -C "$repo_root" rev-parse HEAD)

# Determine version mode: overlay (version dir exists) or WLED-ref (version dir absent)
if [ -d "$repo_root/targets/$target/$version" ]; then
  version_is_overlay=true
else
  version_is_overlay=false
fi

mkdir -p "$log_dir"

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
[ "${#resolved_envs[@]}" -gt 0 ] || die "Could not determine build environment. Pass --environment or set 'environment' in the manifest or shared/platformio.env.ini."

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
[ -n "$wled_ref" ] || die "manifest '$manifest_path' must define non-empty 'wled_ref' (or pass --wled-ref)"

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
set_github_output "apply_log" "$apply_log"
set_github_output "build_log" "$build_log"
set_github_output "meta_json" "$meta_json"
set_github_output "manifest_path" "$manifest_path"
set_github_output "manifest_fallback" "$manifest_fallback"

envs_joined=$(printf '%s,' "${resolved_envs[@]}")
envs_joined=${envs_joined%,}

python - "$meta_json" "$target" "$version" "$wled_ref" "$base_source" "$environment" "$repo_sha" "$timestamp_utc" "$wled_repo" "$manifest_path" "$manifest_fallback" "$version_is_overlay" "$envs_joined" <<'PY'
import json
import sys

(meta_path, target, tgt_version, wled_ref, base_source, environment,
 repo_sha, timestamp, wled_repo, manifest_path, manifest_fallback,
 version_is_overlay, envs_joined) = sys.argv[1:]
environments = [e for e in envs_joined.split(',') if e]
payload = {
  "target": target,
  "tgtVersion": tgt_version,
  "wled_ref": wled_ref,
  "base_source": base_source,
  "environment": environment,
  "environments": environments,
  "multi_env": len(environments) > 1,
  "version_mode": "overlay" if version_is_overlay.lower() == "true" else "wled_ref",
  "repo_sha": repo_sha,
  "timestamp": timestamp,
  "wled_repo": wled_repo,
  "manifest_path": manifest_path,
  "manifest_fallback": manifest_fallback.lower() == "true",
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

set +e
"$script_dir/apply-target.sh" "${apply_args[@]}" 2>&1 | tee "$apply_log"
apply_status=${PIPESTATUS[0]}
set -e
[ "$apply_status" -eq 0 ] || exit "$apply_status"

if [ "$plan_only" = true ]; then
  {
    for _env in "${resolved_envs[@]}"; do
      echo "Plan only: would run 'npm ci', 'npm run build', and 'pio run -e $_env' in $workspace"
    done
  } | tee "$build_log"
  exit 0
fi

set +e
(
  cd "$workspace"
  npm ci
  npm run build
) 2>&1 | tee "$log_dir/npm.log"
npm_status=${PIPESTATUS[0]}
set -e
[ "$npm_status" -eq 0 ] || exit "$npm_status"

for _env in "${resolved_envs[@]}"; do
  _build_log="$log_dir/build.${_env}.log"
  set +e
  (
    cd "$workspace"
    pio run -e "$_env"
  ) 2>&1 | tee "$_build_log"
  _build_status=${PIPESTATUS[0]}
  set -e
  [ "$_build_status" -eq 0 ] || exit "$_build_status"
done
