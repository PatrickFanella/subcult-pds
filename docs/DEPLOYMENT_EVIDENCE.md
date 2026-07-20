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

## OAuth same-site hotfix — 2026-07-20

- Root cause: official PDS `0.4.5009` contains `@atproto/oauth-provider@0.19.5`, which rejected `Sec-Fetch-Site: same-site` when Patchwork redirected from `patchwork.subcult.tv` to `pds.subcult.tv`.
- Upstream fix: `bluesky-social/atproto@af02ea14e710f5930d78b49836aa460cfe168941`, released in `@atproto/oauth-provider@0.19.6` but not yet included in the official PDS distribution image.
- Repository commits: `c65ae89` (strict derived-image patch) and `2b2762f` (honor the host image pin).
- Base image: `ghcr.io/bluesky-social/pds@sha256:1fa8bbceabb65d8e1710749b1ea92c1c20a7489ca38da4a0a5f64c0c10a70c29`.
- Running immutable image ID: `sha256:c92970b008925c705e4c72c09d412277256a598e899e94620357ecb53afca867`.
- Persistent local-registry artifact: `registry:5000/subculture-collective/subcult-pds@sha256:25fab5c68c41e98efed092dd5a5921b70cb55e5fbaefb18b3e590fc5619c1eac`.
- Pre-deploy full-state backup: `/srv/backups/subcult-pds/subcult-pds-20260720T163904Z.tar.gz` with verified SHA-256 sidecar; archive and sidecar mode `0600`.
- Rollback image remains the official base digest above; rollback restores service availability but reintroduces the sibling-subdomain OAuth failure.

Validated:

- Build fails closed unless the package is exactly `0.19.5`, the target file has SHA-256 `b2412fabb840b47b40525160fd3c97b2112e62bd4eb5a11bb30583a74923570e`, and the expected call occurs exactly once.
- Runtime image contains the exact upstream `same-origin`, `same-site`, `cross-site`, `none` allowlist and carries the upstream fix label.
- A real Patchwork PAR request followed by an authorization-page navigation with `Sec-Fetch-Site: same-site` returns HTTP 200 instead of `OAuthErrorResponse`.
- PDS health, metadata, WebSocket smoke test, wildcard handle resolution, Patchwork readiness, and the public account-creation 404 boundary all still pass.
- No Caddy request-header rewriting was introduced.

Remove the derived image and restore an official digest once the official PDS distribution includes `@atproto/oauth-provider >=0.19.6`.
