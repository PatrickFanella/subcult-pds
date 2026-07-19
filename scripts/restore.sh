#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need tar
need sha256sum
need docker

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
confirm=no
archive=${1:-}
[[ $# -ge 1 ]] || die "usage: restore.sh --yes /path/to/archive.tar.gz"
if [[ ${1:-} == --yes ]]; then
  confirm=yes
  archive=${2:-}
fi
[[ $confirm == yes ]] || die "restores require --yes"
[[ -n "$archive" && -f "$archive" ]] || die "missing archive: $archive"
[[ -f "$archive.sha256" ]] || die "missing checksum sidecar: $archive.sha256"

data_dir=${PDS_DATA_DIR:-/srv/data/subcult-pds}
[[ -d "$data_dir" ]] || die "missing data dir: $data_dir"

[[ -z "$(docker compose -f "$repo_root/compose.yaml" ps -q --status running pds)" ]] || die "PDS must be stopped before restore"

sha256sum -c "$archive.sha256"

while IFS= read -r entry; do
  [[ -n "$entry" ]] || continue
  case "$entry" in
    /*|*../*|*..\\*|..|.) die "unsafe archive entry: $entry" ;;
  esac
done < <(tar -tzf "$archive")

moved="$data_dir/.pre-restore.$(date -u +%Y%m%dT%H%M%SZ)"
mkdir "$moved"
shopt -s dotglob nullglob
for entry in "$data_dir"/*; do
  [[ "$entry" == "$moved" ]] && continue
  mv -- "$entry" "$moved/"
done
shopt -u dotglob nullglob

tar -C "$data_dir" -xzf "$archive"

printf '%s\n' "restored $archive; previous contents retained at $moved"
