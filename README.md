# subcult-pds

Invite-only Bluesky PDS for `pds.subcult.tv`.

## Constraints

- Official image only: `ghcr.io/bluesky-social/pds:0.4@sha256:1fa8bbceabb65d8e1710749b1ea92c1c20a7489ca38da4a0a5f64c0c10a70c29`
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
- OAuth same-site hotfix image is documented in `Dockerfile.oauth-samesite`
- No Watchtower
- SMTP is intentionally unset; password recovery is unavailable until configured
- Signup links use the Subcult privacy policy, terms, and contact pages
- Existing reserved host labels and subdomains must not be issued as handles

## OAuth hotfix

This repo carries a derived-image hotfix for upstream ATProto commit `af02ea14e710f5930d78b49836aa460cfe168941`.
It patches `@atproto/oauth-provider@0.19.5` so `validateFetchSite(...)` accepts `'same-site'`.

Build/test/push flow uses the local registry at `10.0.0.56:5000`:

1. Build the derived image with `scripts/test-oauth-image.sh` or `docker build -f Dockerfile.oauth-samesite -t ... .`
2. Run `scripts/test-oauth-image.sh` to verify labels and the patched call inside the image.
3. Tag and push the verified image by digest to `10.0.0.56:5000`.
4. After review, pin the pushed digest in the host `.env` only; do not change `compose.yaml` yet.

Rollback caveat: keep the previous digest available until the new image is validated in production.

Remove this hotfix once the official PDS distribution includes `oauth-provider >= 0.19.6`.

## Quick start

1. Copy `.env.example` to `.env` and adjust host paths if needed.
2. Run `scripts/init.sh` once to create `${PDS_DATA_DIR}/pds.env`.
3. Run `scripts/preflight.sh`.
4. Validate `docker compose -f compose.yaml config --quiet`.
5. Start with Docker Compose.

## Warning

Backups use a running-state check before stopping PDS and always write a checksum sidecar.

Restores require `--yes`, a checksum sidecar, and reject absolute or traversal archive entries before extraction.

Smoke validation checks HTTP success, JSON validity, `inviteCodeRequired === true`, and WebSocket connectivity unless `SKIP_WEBSOCKET_CHECK=1`.

## License

Licensed under `GPL-3.0-or-later`. See [LICENSE](LICENSE).
