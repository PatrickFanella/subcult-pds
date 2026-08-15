# Operations

## Warning

Reserved Subcult hosts and subdomains must not be issued as user handles.
Do not distribute reusable invite codes until signup policy enforces that reservation. Prefer operator-created accounts during the initial pilot.

## Deployment

- Use the pinned official PDS image only.
- Do not install Watchtower on identity infrastructure.
- Keep secrets in `${PDS_DATA_DIR}/pds.env` only.
- Validate with `docker compose -f compose.yaml config` before deployment.
- Cloudflare terminates public TLS for this host. Almaz Caddy therefore uses `http://` site labels for the Cloudflare-to-origin hop, matching the existing shared edge convention; clients still use HTTPS.
- The exact `pds.subcult.tv` route proxies all PDS traffic except public account creation, which Caddy deliberately answers with a minimal 404 at `/xrpc/com.atproto.server.createAccount` before the reverse proxy. All other PDS endpoints remain proxied, and the wildcard route still proxies only `/.well-known/atproto-did`; existing and future applications require exact-host Caddy routes, which are more specific than the wildcard.
- SMTP is intentionally unset; password recovery is unavailable until configured.

## Retired OAuth same-site hotfix

- Official PDS `0.4.5027` ships `@atproto/oauth-provider@0.22.1` and replaces the former derived-image fix for upstream ATProto commit `af02ea14e710f5930d78b49836aa460cfe168941`.
- The derived Dockerfile, patch script, and patch-specific test were removed only after production OAuth, same-site, callback, and record-round-trip qualification succeeded.
- The retired image ID, local-registry digest, prior official base digest, and stopped-service backup remain recorded in `docs/DEPLOYMENT_EVIDENCE.md` as the upgrade rollback boundary.

## Backups

- `scripts/backup.sh` only stops/restarts PDS if it was already running.
- `scripts/backup.sh` creates a tarball and SHA-256 sidecar.
- Archive the full data directory, including databases and blobs.
- The local backup directory is mode `0700`, but backups are not encrypted. Add encrypted off-host replication before hosting identities for other people.

## Restore

- PDS must be stopped.
- Restore requires `--yes`.
- Restore validates the SHA-256 sidecar.
- Existing data is moved into a timestamped `.pre-restore.*` directory before extraction; nothing is silently deleted. Remove that retained copy only after validating the restored PDS.

## Accounts and invites

- `scripts/admin.sh create-invites` creates invite codes.
- Create an account with `scripts/admin.sh account create --handle alice.subcult.tv --email alice@example.com --password '<initial-password>'`.
- The wrapper relies on the container's `PDS_ADMIN_PASSWORD` environment variable without printing it; account passwords supplied on the command line may still be visible to local process inspection and shell history.
- Reserved existing host labels and subdomains must not be issued as handles.
- Public signup is intentionally gated at Patchwork's `/api/auth/signup` admission check, which enforces origin/rate limits/reserved labels and forwards credentials only in memory; never log signup bodies.

## Validation

- Non-destructive example: `curl -i -X POST -H 'content-type: application/json' --data '{}' http://pds.subcult.tv/xrpc/com.atproto.server.createAccount` should return `404` without reaching the PDS, while `curl -i http://pds.subcult.tv/xrpc/_health` should still return `200`.

## Upgrades

- Pin the reviewed multi-architecture image index digest, not a floating tag or a platform-specific child manifest.
- Before stopping the service, verify that the configured backup directory exists or can be created on the intended filesystem, has sufficient free space, and contains any rollback backup that must be retained.
- Run `scripts/backup.sh`; it takes the archive while the service is stopped and restores the prior running state before returning. Immediately verify the returned archive with `sha256sum -c`, then record the archive and sidecar paths.
- Retain the currently running immutable image ID and the verified backup as the rollback boundary.
- Pull the candidate and run compose config validation before recreating the service.
- After restart, run `PDS_EXPECTED_VERSION=0.4.5027 scripts/smoke-test.sh` and verify all of the following before declaring success:
  - `_health` returns HTTP 200 and the expected version.
  - `describeServer` returns `did:web:pds.subcult.tv`, `.subcult.tv`, and invite-required registration.
  - `com.atproto.sync.subscribeRepos` accepts a WebSocket upgrade.
  - a known wildcard handle resolves through `/.well-known/atproto-did`.
  - the public `com.atproto.server.createAccount` boundary remains a minimal 404.
  - Patchwork completes OAuth PAR, authorization-page navigation, and callback.
  - a real test record can be written and read back through Patchwork.
  - authorization-page navigation with `Sec-Fetch-Site: same-site` succeeds without request-header rewriting.
  - account administration still works through `scripts/admin.sh`.
- If any required check fails, restore the prior image pin; restore the verified stopped-service backup only if the candidate changed persistent state incompatibly.
- Update `docs/DEPLOYMENT_EVIDENCE.md` with the deployed digest, backup and checksum, validation results, and rollback point only after every production check succeeds. Retire any temporary patch artifacts at that same post-qualification boundary.
- This is independent PDS maintenance. Jetstream is downstream infrastructure and requires no PDS endpoint, archive, API-key, crawler, or data-directory change.
