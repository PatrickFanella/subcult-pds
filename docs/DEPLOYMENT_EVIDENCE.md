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

This derived image was retired after the official `0.4.5027` production qualification recorded below.

## Official PDS 0.4.5027 upgrade — 2026-08-14 Central / 2026-08-15 UTC

- Maintenance classification: independent PDS upgrade; not required by Jetstream or Bluesky Protocol Services.
- Official image: `ghcr.io/bluesky-social/pds:0.4.5027@sha256:d95725b24dbe53af9d91dc69750556931ebed6c396f2cfa42b221434db642f12`.
- Multi-architecture index digest: `sha256:d95725b24dbe53af9d91dc69750556931ebed6c396f2cfa42b221434db642f12`.
- Linux amd64 manifest: `sha256:4c94fa7f2ef793dc44e046cb167ae187199aab323f1dc9abe81ee53dc0b34a6b`.
- Linux arm64 manifest: `sha256:21d75ae07179ecaa869840fec7ca96e16dc63bf1caa2de8ca85ab574799cdea7`.
- Packaged runtime: `@atproto/pds@0.5.27`, `@atproto/oauth-provider@0.22.1`, Node `v24.18.1`.
- Verified stopped-service backup: `/srv/backups/subcult-pds/subcult-pds-20260815T041206Z.tar.gz` with SHA-256 sidecar; archive integrity and checksum validation passed, and both files are mode `0600`.
- Host image-pin rollback copy: `/srv/backups/subcult-pds/subcult-pds-image-pin-pre-0.4.5027-20260815T041206Z.env` (mode `0600`).
- Retired derived-image rollback ID: `sha256:c92970b008925c705e4c72c09d412277256a598e899e94620357ecb53afca867`, retained in the NUC Docker cache.
- Retired local-registry rollback artifact: `registry:5000/subculture-collective/subcult-pds@sha256:25fab5c68c41e98efed092dd5a5921b70cb55e5fbaefb18b3e590fc5619c1eac`, reverified before deployment.
- Prior official base rollback digest: `sha256:1fa8bbceabb65d8e1710749b1ea92c1c20a7489ca38da4a0a5f64c0c10a70c29`.

Validated in production:

- Docker reports the exact official image healthy; origin and public `_health` return HTTP 200 with version `0.4.5027`.
- `describeServer` reports `did:web:pds.subcult.tv`, `.subcult.tv`, and invite-required registration.
- `com.atproto.sync.subscribeRepos` accepts a public WebSocket connection.
- `patrick.subcult.tv/.well-known/atproto-did` resolves through the wildcard PDS route.
- The public `com.atproto.server.createAccount` boundary remains an empty HTTP 404.
- `scripts/admin.sh account list` works through the upgraded container and reports the existing active accounts without requiring secret extraction.
- A real Chromium Patchwork login produced a successful PAR response, loaded the PDS authorization page, granted consent, and completed the callback to an authenticated Patchwork session.
- The sibling-subdomain authorization navigation carried `Sec-Fetch-Site: same-site` with referer `https://patchwork.subcult.tv/` and returned the authorization UI without request-header rewriting.
- Patchwork created a disposable `app.patchwork.aid.post` record, read it back directly from the PDS by exact URI and CID, deleted it through Patchwork with CID compare-and-swap, and received `RecordNotFound` on the subsequent PDS read. Patchwork's feed query no longer returned the URI, and the browser session was signed out and closed.
- The derived Dockerfile, patch script, and patch-specific test were removed only after all preceding checks passed.
- No PDS endpoint, Jetstream archive, Jetstream API key, PDS data-directory layout, or `PDS_CRAWLERS=https://bsky.network` change was made.
