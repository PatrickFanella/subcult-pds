#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need docker
need node

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file=${PDS_ENV_FILE:-${PDS_DATA_DIR:-/srv/data/subcult-pds}/pds.env}
data_dir=${PDS_DATA_DIR:-/srv/data/subcult-pds}
backup_dir=${PDS_BACKUP_DIR:-/srv/backups/subcult-pds}

[[ -f "$repo_root/compose.yaml" ]] || die "missing compose.yaml"
[[ -f "$repo_root/.env.example" ]] || die "missing .env.example"
[[ -d "$data_dir" || ! -e "$data_dir" ]] || die "PDS_DATA_DIR exists and is not a directory: $data_dir"
[[ -d "$backup_dir" || ! -e "$backup_dir" ]] || die "PDS_BACKUP_DIR exists and is not a directory: $backup_dir"
[[ "$env_file" == "$data_dir/pds.env" ]] || die "secrets must live at ${data_dir}/pds.env"

if [[ -e "$env_file" && ! -f "$env_file" ]]; then
  die "pds.env exists but is not a regular file: $env_file"
fi
[[ -f "$env_file" ]] || die "missing $env_file; run scripts/init.sh first"

docker compose -f "$repo_root/compose.yaml" config --quiet

node_major=$(node -p 'Number(process.versions.node.split(".")[0])')
(( node_major >= 22 )) || die "Node.js 22+ is required for the WebSocket smoke test"

printf 'preflight ok\n'
