# Deployment evidence

Date: 2026-07-19

- Public hostname: `pds.subcult.tv`
- PDS version: `0.4.5009`
- Image: `ghcr.io/bluesky-social/pds:0.4@sha256:1fa8bbceabb65d8e1710749b1ea92c1c20a7489ca38da4a0a5f64c0c10a70c29`
- Origin binding: `10.0.0.56:3043`
- Persistent data: `/srv/data/subcult-pds` (`0700`)
- Secret file: `/srv/data/subcult-pds/pds.env` (`0600`)
- Final initial backup: `/srv/backups/subcult-pds/subcult-pds-20260719T193957Z.tar.gz` with SHA-256 sidecar (`0600`)
- Caddy rollback copy: `/mnt/spektr/server/management/config/caddy/Caddyfile.20260719T193307Z.bak` on Almaz

Validated:

- Docker reports the PDS healthy.
- Public health and `describeServer` return JSON over HTTPS.
- `describeServer` reports `did:web:pds.subcult.tv`, `.subcult.tv`, and invite-only account creation.
- WebSocket connection to `com.atproto.sync.subscribeRepos` succeeds.
- Wildcard handle-resolution requests reach the PDS.
- Existing Subcult, Patchwork, Git, Grafana, and Edda routes remain reachable.
- Caddy configuration validates after reload.
- Stopped-service backup checksum and a complete restore drill succeeded.

Known launch constraints:

- SMTP is not configured, so automated email verification and password recovery are unavailable.
- Backups are protected by filesystem permissions but are not yet encrypted or replicated off-host.
- No user account or invite code was created during deployment.
