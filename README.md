# subcult-pds

Invite-only Bluesky PDS for `pds.subcult.tv`.

## Constraints

- Official image: `ghcr.io/bluesky-social/pds:0.4.5027@sha256:d95725b24dbe53af9d91dc69750556931ebed6c396f2cfa42b221434db642f12`
- Default bind: `10.0.0.56:3043`
- Default data dir: `/srv/data/subcult-pds`
- Default backup dir: `/srv/backups/subcult-pds`
- Secrets live only in `${PDS_DATA_DIR}/pds.env`
- `PDS_HOSTNAME=pds.subcult.tv`
- `PDS_SERVICE_HANDLE_DOMAINS=.subcult.tv`
- `PDS_BSKY_APP_VIEW_DID=did:web:api.bsky.app`
- `PDS_RATE_LIMITS_ENABLED=true`
- `PDS_INVITE_REQUIRED=true`
- `PDS_BLOB_UPLOAD_LIMIT=104857600`
- `PDS_CONTACT_EMAIL_ADDRESS=security@subcult.tv`
- No Watchtower
- SMTP is intentionally unset; password recovery is unavailable until configured
- Signup links use the Subcult privacy policy, terms, and contact pages
- Existing reserved host labels and subdomains must not be issued as handles

## OAuth same-site fix

The official `0.4.5027` distribution contains `@atproto/oauth-provider@0.22.1` and accepts sibling-subdomain OAuth navigation with `Sec-Fetch-Site: same-site`.
The previous derived-image hotfix is retired; its immutable rollback digests and deployment history remain recorded in `docs/DEPLOYMENT_EVIDENCE.md`.

## Quick start

1. Copy `.env.example` to `.env` and adjust host paths if needed.
2. Run `scripts/init.sh` once to create `${PDS_DATA_DIR}/pds.env`.
3. Run `scripts/preflight.sh`.
4. Validate `docker compose -f compose.yaml config --quiet`.
5. Start with Docker Compose.

## Warning

Backups use a running-state check before stopping PDS and always write a checksum sidecar.

Restores require `--yes`, a checksum sidecar, and reject absolute or traversal archive entries before extraction.

Smoke validation checks health and optional expected version, the server identity and invite policy, the public account-creation 404 boundary, and WebSocket connectivity unless `SKIP_WEBSOCKET_CHECK=1`.
Set `PDS_TEST_HANDLE` to a known existing handle to include wildcard resolution.
