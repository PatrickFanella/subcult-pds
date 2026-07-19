#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need docker
need sha256sum

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
data_dir=${PDS_DATA_DIR:-/srv/data/subcult-pds}
backup_dir=${PDS_BACKUP_DIR:-/srv/backups/subcult-pds}
stamp=$(date -u +%Y%m%dT%H%M%SZ)
archive="$backup_dir/subcult-pds-$stamp.tar.gz"

[[ -d "$data_dir" ]] || die "missing data dir: $data_dir"
mkdir -p "$backup_dir"

restart_needed=0
cleanup() {
  if [[ $restart_needed -eq 1 ]]; then
    docker compose -f "$repo_root/compose.yaml" up -d pds >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

if [[ -n "$(docker compose -f "$repo_root/compose.yaml" ps -q --status running pds)" ]]; then
  restart_needed=1
  docker compose -f "$repo_root/compose.yaml" stop pds
fi

tar -C "$data_dir" -czf "$archive" .
sha256sum "$archive" >"$archive.sha256"

if [[ $restart_needed -eq 1 ]]; then
  docker compose -f "$repo_root/compose.yaml" up -d pds
  restart_needed=0
fi
trap - EXIT INT TERM

printf '%s\n' "$archive"
