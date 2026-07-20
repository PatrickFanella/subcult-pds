#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need docker
need node

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=${1:-subcult-pds-oauth-samesite:local}

docker build -f "$repo_root/Dockerfile.oauth-samesite" -t "$image" "$repo_root"

docker image inspect "$image" --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' | grep -Fx 'af02ea14e710f5930d78b49836aa460cfe168941' >/dev/null
docker image inspect "$image" --format '{{ index .Config.Labels "org.opencontainers.image.base.digest" }}' | grep -Fx 'sha256:1fa8bbceabb65d8e1710749b1ea92c1c20a7489ca38da4a0a5f64c0c10a70c29' >/dev/null

docker run --rm "$image" node -e "const fs=require('fs'); const p='/app/node_modules/.pnpm/@atproto+oauth-provider@0.19.5/node_modules/@atproto/oauth-provider/package.json'; const pkg=JSON.parse(fs.readFileSync(p,'utf8')); if (pkg.version !== '0.19.5') throw new Error('version mismatch'); const f='/app/node_modules/.pnpm/@atproto+oauth-provider@0.19.5/node_modules/@atproto/oauth-provider/dist/router/create-authorization-page-middleware.js'; const s=fs.readFileSync(f,'utf8'); const old=\"validateFetchSite(req, ['same-origin', 'cross-site', 'none']);\"; const neu=\"validateFetchSite(req, ['same-origin', 'same-site', 'cross-site', 'none']);\"; if ((s.split(old).length-1)!==0) throw new Error('old call still present'); if ((s.split(neu).length-1)!==1) throw new Error('new call missing');"

printf '%s\n' "$image"
