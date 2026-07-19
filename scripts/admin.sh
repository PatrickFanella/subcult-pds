#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need docker

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
data_dir=${PDS_DATA_DIR:-/srv/data/subcult-pds}
env_file="$data_dir/pds.env"
[[ -f "$env_file" ]] || die "missing secrets file: $env_file"
[[ $# -ge 1 ]] || die "usage: admin.sh <goat pds admin arguments...>"

docker compose -f "$repo_root/compose.yaml" exec -T pds \
  goat pds admin "$@"
