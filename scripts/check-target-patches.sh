#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-target-patches.sh --target <target> --version <version> [--wled-ref <ref>] [--wled-repo <url>]

Fetches the WLED ref a target/version tracks (from targets/<target>/<version>/build.json,
or override with --wled-ref/--wled-repo) into a scratch checkout and dry-runs every patch in
targets/<target>/shared/patches/ and targets/<target>/<version>/patches/ (git apply --check),
without applying anything or building. Prints a pass/fail table per patch file and exits
non-zero if any patch would fail to apply.

Use this to catch upstream drift (an upstream commit that no longer applies a target's patches
cleanly) before it turns into a build failure - especially useful for version dirs that track a
moving ref like "main" or "nightly" instead of a pinned tag.

  --target <target>     Required. e.g. waveshare-esp32s3-eth
  --version <version>   Required. e.g. v17
  --wled-ref <ref>      Override the ref to fetch (default: read from build.json)
  --wled-repo <url>     Override the repo to fetch from (default: read from build.json, or
                         https://github.com/wled/WLED.git)
  --keep-workspace      Do not delete the scratch checkout on exit (prints its path)
USAGE
}

die() {
  echo "Error: $*" >&2
  exit 1
}

json_get_value() {
  local json_file=$1
  local json_key=$2
  python3 - "$json_file" "$json_key" <<'PY'
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

target=
version=
wled_ref=
wled_repo=
keep_workspace=false

while [ $# -gt 0 ]; do
  case "$1" in
    --target) target=${2:-}; shift 2 ;;
    --version) version=${2:-}; shift 2 ;;
    --wled-ref) wled_ref=${2:-}; shift 2 ;;
    --wled-repo) wled_repo=${2:-}; shift 2 ;;
    --keep-workspace) keep_workspace=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$target" ] || die "--target is required"
[ -n "$version" ] || die "--version is required"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
base_dir="$repo_root/targets/$target"
shared_dir="$base_dir/shared"
version_dir="$base_dir/$version"
manifest_path="$version_dir/build.json"

[ -d "$base_dir" ] || die "target '$target' does not exist under $repo_root/targets"
[ -d "$version_dir" ] || die "version '$version' does not exist for target '$target'"

if [ -z "$wled_ref" ]; then
  if [ -f "$manifest_path" ]; then
    wled_ref=$(json_get_value "$manifest_path" "wled_ref")
  fi
fi
[ -n "$wled_ref" ] || die "could not determine wled_ref: pass --wled-ref or add it to $manifest_path"

if [ -z "$wled_repo" ]; then
  if [ -f "$manifest_path" ]; then
    wled_repo=$(json_get_value "$manifest_path" "wled_repo")
  fi
fi
[ -n "$wled_repo" ] || wled_repo="https://github.com/wled/WLED.git"

workspace=$(mktemp -d "/tmp/wled-patch-check-${target}-${version}-XXXXXX")
cleanup() {
  local status=$?
  if [ "$keep_workspace" = false ]; then
    rm -rf "$workspace"
  else
    echo "Workspace kept at: $workspace"
  fi
  exit "$status"
}
trap cleanup EXIT

echo "Target:    $target"
echo "Version:   $version"
echo "WLED ref:  $wled_ref"
echo "WLED repo: $wled_repo"
echo "Fetching into scratch workspace: $workspace"
echo

git -C "$workspace" init -q || die "failed to initialize workspace git repository at $workspace"
git -C "$workspace" remote add origin "$wled_repo" || die "failed to add remote '$wled_repo'"
git -C "$workspace" fetch --depth 1 origin "$wled_ref" || die "failed to fetch WLED ref '$wled_ref' from '$wled_repo'"
git -C "$workspace" checkout -q --detach FETCH_HEAD || die "failed to checkout fetched WLED ref '$wled_ref'"
fetched_sha=$(git -C "$workspace" rev-parse HEAD)
echo "Fetched commit: $fetched_sha"
echo

[ -d "$workspace/wled00" ] || die "fetched workspace does not look like a WLED checkout"

declare -a results=()
overall_ok=true

check_patches_dir() {
  local patches_dir=$1
  local label=$2

  [ -d "$patches_dir" ] || return 0

  local patch_file
  for patch_file in "$patches_dir"/*.patch; do
    [ -f "$patch_file" ] || continue
    local rel="${patch_file#"$repo_root"/}"
    if git -C "$workspace" apply --check "$patch_file" 2>/tmp/check-target-patches.$$.err; then
      results+=("PASS  $label  $rel")
    else
      results+=("FAIL  $label  $rel")
      overall_ok=false
      echo "--- git apply --check failure for $rel ---"
      cat /tmp/check-target-patches.$$.err >&2
      echo "---"
    fi
    rm -f /tmp/check-target-patches.$$.err
  done
}

check_patches_dir "$shared_dir/patches" "shared "
check_patches_dir "$version_dir/patches" "$version"

echo
echo "Patch check results ($target / $version against $wled_ref @ ${fetched_sha:0:12}):"
if [ "${#results[@]}" -eq 0 ]; then
  echo "  (no patches found in shared/patches or $version/patches)"
else
  result_line=
  for result_line in "${results[@]}"; do
    echo "  $result_line"
  done
fi

echo
if [ "$overall_ok" = true ]; then
  echo "All patches apply cleanly against $wled_ref @ ${fetched_sha:0:12}."
  exit 0
else
  echo "One or more patches FAILED to apply against $wled_ref @ ${fetched_sha:0:12}."
  echo "Upstream has likely drifted since these patches were written - review and update them."
  exit 1
fi
