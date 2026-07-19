#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }
gen_hex() { openssl rand --hex 16; }

need docker
need openssl
need tail
need head
need xxd

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
data_dir=${PDS_DATA_DIR:-/srv/data/subcult-pds}
env_file="$data_dir/pds.env"
hostname=${PDS_HOSTNAME:-pds.subcult.tv}
handle_domains=${PDS_SERVICE_HANDLE_DOMAINS:-.subcult.tv}

[[ -d "$data_dir" || ! -e "$data_dir" ]] || die "data dir exists and is not a directory: $data_dir"
mkdir -p "$data_dir"
[[ ! -e "$env_file" ]] || die "refusing to overwrite existing $env_file"

jwt_secret=$(gen_hex)
admin_password=$(gen_hex)
plc_key=$(openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)

cat >"$env_file" <<EOF
PDS_HOSTNAME=$hostname
PDS_SERVICE_NAME=Subcult PDS
PDS_HOME_URL=https://subcult.tv
PDS_PRIVACY_POLICY_URL=https://subcult.tv/privacy
PDS_TERMS_OF_SERVICE_URL=https://subcult.tv/terms
PDS_SUPPORT_URL=https://subcult.tv/contact
PDS_JWT_SECRET=$jwt_secret
PDS_ADMIN_PASSWORD=$admin_password
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$plc_key
PDS_SERVICE_HANDLE_DOMAINS=$handle_domains
PDS_DID_PLC_URL=https://plc.directory
PDS_BLOBSTORE_DISK_LOCATION=/pds/blocks
PDS_DATA_DIRECTORY=/pds
PDS_BSKY_APP_VIEW_URL=https://api.bsky.app
PDS_BSKY_APP_VIEW_DID=did:web:api.bsky.app
PDS_REPORT_SERVICE_URL=https://mod.bsky.app
PDS_REPORT_SERVICE_DID=did:plc:ar7c4by46qjdydhdevvrndac
PDS_CRAWLERS=https://bsky.network
LOG_ENABLED=true
PDS_RATE_LIMITS_ENABLED=true
PDS_INVITE_REQUIRED=true
PDS_BLOB_UPLOAD_LIMIT=104857600
PDS_CONTACT_EMAIL_ADDRESS=security@subcult.tv
PDS_EMAIL_SMTP_URL=
PDS_EMAIL_FROM_ADDRESS=
EOF

printf 'wrote %s\n' "$env_file"
