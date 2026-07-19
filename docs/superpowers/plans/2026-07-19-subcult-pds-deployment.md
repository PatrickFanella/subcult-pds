# Subcult PDS Deployment Implementation Plan

> **For agentic workers:** Execute this plan task-by-task. Recommended path:
> dispatch a fresh subagent per task, review each result with `review-quality`,
> then continue. For complex multi-agent splits, use
> `parallel-feature-development`, `team-composition-patterns`, and
> `team-communication-protocols`. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Run an invite-only AT Protocol PDS at `pds.subcult.tv` from an independent, reproducible repository.

**Architecture:** Run the official Bluesky PDS image on the NUC, bind it only to the NUC LAN address, and persist `/pds` outside the repository. Route public PDS and handle-resolution traffic through the existing Cloudflare and Almaz Caddy edge; retain identity-critical secrets in the protected data directory and use stopped-service backups.

**Tech Stack:** Docker Compose, official Bluesky PDS container, Bash operator scripts, Caddy, SQLite and disk blob storage.

---

## File map

- `compose.yaml`: pinned PDS runtime, LAN-only port, persistent bind mount, and health check.
- `.env.example`: non-secret host deployment settings.
- `.gitignore`: excludes runtime environment, backups, and credentials.
- `deploy/caddy/subcult-pds.Caddyfile`: exact PDS host and narrowly scoped handle-resolution proxy.
- `scripts/init.sh`: generate official PDS secrets and initialize protected storage.
- `scripts/preflight.sh`: reject unsafe or incomplete deployment configuration.
- `scripts/backup.sh`: stop, archive, checksum, and restart the identity data store.
- `scripts/restore.sh`: explicitly gated, checksum-verified restore into stopped protected storage.
- `scripts/admin.sh`: invoke official PDS account and invite administration without printing the admin password.
- `scripts/smoke-test.sh`: validate health, server description, handle domains, and WebSocket upgrade.
- `docs/OPERATIONS.md`: deployment, proxy, account administration, upgrades, backup, and incident runbook.
- `README.md`: scope, quick start, and security constraints.

### Task 1: Runtime contract

- [ ] Create `compose.yaml` using `ghcr.io/bluesky-social/pds:0.4` pinned by digest, `10.0.0.56:3043:3000`, `/srv/data/subcult-pds:/pds`, and `/srv/data/subcult-pds/pds.env`.
- [ ] Add a localhost container health check for `/xrpc/_health`.
- [ ] Create `.env.example` with the image, bind address, port, data directory, backup directory, and public hostname.
- [ ] Run `docker compose config --quiet`; expect exit status 0.

### Task 2: Safe initialization

- [ ] Create `scripts/init.sh` with `set -Eeuo pipefail`, dependency checks, restrictive umask, and refusal to overwrite an existing `pds.env`.
- [ ] Generate `PDS_JWT_SECRET` and `PDS_ADMIN_PASSWORD` with `openssl rand --hex 16`.
- [ ] Generate `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX` with the official secp256k1 installer command.
- [ ] Configure `PDS_HOSTNAME=pds.subcult.tv`, `PDS_SERVICE_HANDLE_DOMAINS=.subcult.tv`, rate limits, invites, PLC, AppView, reporting, and crawler endpoints.
- [ ] Leave SMTP unset and record that password recovery is unavailable until SMTP is configured.

### Task 3: Edge routing

- [ ] Create `deploy/caddy/subcult-pds.Caddyfile` with an exact `pds.subcult.tv` proxy to `10.0.0.56:3043`.
- [ ] Add a wildcard `*.subcult.tv` route that proxies only `/.well-known/atproto-did`; return 404 for all other unmatched wildcard requests.
- [ ] Add the site import to Almaz Caddy only after saving a timestamped backup.
- [ ] Run `caddy validate` before reload; expect `Valid configuration`.
- [ ] Confirm existing named project hosts still return their existing content after reload.

### Task 4: Operations tooling

- [ ] Create backup and restore scripts that stop the PDS before copying SQLite/WAL data.
- [ ] Create invite and interactive account-administration wrappers that read secrets internally and never print the admin password.
- [ ] Document the reserved-handle constraint: labels already used by Subcult services must not be issued as user handles.
- [ ] Document manual digest upgrades and prohibit Watchtower for identity infrastructure.

### Task 5: Deployment validation

- [ ] Pull the pinned image and verify its resolved repo digest.
- [ ] Run preflight and initialize protected storage.
- [ ] Start the PDS and wait for Docker health.
- [ ] Verify `https://pds.subcult.tv/xrpc/_health` returns PDS JSON, not an empty proxy response.
- [ ] Verify `com.atproto.server.describeServer` reports `.subcult.tv` and invite-only mode.
- [ ] Verify a WebSocket upgrade reaches `com.atproto.sync.subscribeRepos`.
- [ ] Verify representative existing project hosts still return 200.

### Task 6: Recovery evidence

- [ ] Produce an initial stopped-service backup with SHA-256 sidecar.
- [ ] Verify the archive contains `pds.env`, the PLC rotation key material or configured key, databases, and blob directory as applicable.
- [ ] Record restore and secret-compromise procedures in `docs/OPERATIONS.md`.
