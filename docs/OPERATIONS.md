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

- Update the image digest manually.
- Run compose config validation and smoke-test before release.
