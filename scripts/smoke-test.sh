#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

need node

host=${PDS_PUBLIC_HOSTNAME:-${PDS_HOSTNAME:-pds.subcult.tv}}
base=${PDS_SMOKE_BASE_URL:-https://$host}
skip_ws=${SKIP_WEBSOCKET_CHECK:-0}

node <<'NODE'
const base = process.env.PDS_SMOKE_BASE_URL || `https://${process.env.PDS_PUBLIC_HOSTNAME || process.env.PDS_HOSTNAME || 'pds.subcult.tv'}`;
const skipWs = process.env.SKIP_WEBSOCKET_CHECK === '1';
const req = async (path, opts={}) => {
  const r = await fetch(base + path, opts);
  return {r, text: await r.text()};
};
(async () => {
  const h = await req('/xrpc/_health');
  if (!h.r.ok) throw new Error('health not ok');
  const health = JSON.parse(h.text);
  if (!health || typeof health.version !== 'string' || !health.version) throw new Error('health version missing');
  const expectedVersion = process.env.PDS_EXPECTED_VERSION;
  if (expectedVersion && health.version !== expectedVersion) throw new Error(`unexpected health version: ${health.version}`);
  const d = await req('/xrpc/com.atproto.server.describeServer');
  const j = JSON.parse(d.text);
  if (!j || typeof j !== 'object') throw new Error('invalid describeServer JSON');
  if (j.did !== 'did:web:pds.subcult.tv') throw new Error(`unexpected server DID: ${j.did}`);
  if (!String(j.availableUserDomains || '').includes('.subcult.tv')) throw new Error('missing .subcult.tv');
  if (j.inviteCodeRequired !== true) throw new Error('invite requirement missing');
  if (d.r.status < 200 || d.r.status >= 300) throw new Error('describeServer not successful');
  const create = await req('/xrpc/com.atproto.server.createAccount', {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: '{}',
  });
  if (create.r.status !== 404) throw new Error(`public account creation boundary returned ${create.r.status}`);
  if (create.text !== '') throw new Error('public account creation boundary returned a non-empty body');
  const testHandle = process.env.PDS_TEST_HANDLE;
  if (testHandle) {
    const wellKnown = await fetch(`https://${testHandle}/.well-known/atproto-did`);
    const did = (await wellKnown.text()).trim();
    if (!wellKnown.ok || !did.startsWith('did:')) throw new Error(`wildcard handle resolution failed for ${testHandle}`);
  }
  if (!skipWs) {
    const wsUrl = base.replace(/^http/, 'ws') + '/xrpc/com.atproto.sync.subscribeRepos';
    const ws = new WebSocket(wsUrl);
    await new Promise((resolve, reject) => {
      ws.onopen = () => { ws.close(); resolve(); };
      ws.onerror = reject;
      setTimeout(() => reject(new Error('ws timeout')), 5000);
    });
  }
})().then(() => process.exit(0)).catch(err => { console.error(err.message); process.exit(1); });
NODE
