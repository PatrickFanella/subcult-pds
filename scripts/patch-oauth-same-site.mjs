#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';

const target = '/app/node_modules/.pnpm/@atproto+oauth-provider@0.19.5/node_modules/@atproto/oauth-provider/dist/router/create-authorization-page-middleware.js';
const expectedSha = 'b2412fabb840b47b40525160fd3c97b2112e62bd4eb5a11bb30583a74923570e';
const oldCall = "validateFetchSite(req, ['same-origin', 'cross-site', 'none']);";
const newCall = "validateFetchSite(req, ['same-origin', 'same-site', 'cross-site', 'none']);";

const fail = (msg) => { console.error(msg); process.exit(1); };

let src;
try { src = readFileSync(target, 'utf8'); } catch { fail(`missing target: ${target}`); }

const packageJson = '/app/node_modules/.pnpm/@atproto+oauth-provider@0.19.5/node_modules/@atproto/oauth-provider/package.json';
let pkg;
try { pkg = JSON.parse(readFileSync(packageJson, 'utf8')); } catch { fail(`missing package metadata: ${packageJson}`); }

if (!target.includes('@atproto+oauth-provider@0.19.5/')) fail('target path does not pin oauth-provider 0.19.5');
if (pkg.version !== '0.19.5') fail(`package version mismatch: ${pkg.version}`);

const sha = createHash('sha256').update(src).digest('hex');
if (sha !== expectedSha) fail(`prepatch sha mismatch: ${sha}`);

const oldCount = src.split(oldCall).length - 1;
const newCount = src.split(newCall).length - 1;
if (oldCount !== 1) fail(`expected exactly one old call, found ${oldCount}`);
if (newCount !== 0) fail(`unexpected existing new call count: ${newCount}`);

const patched = src.replace(oldCall, newCall);
if ((patched.split(oldCall).length - 1) !== 0) fail('old call still present after patch');
if ((patched.split(newCall).length - 1) !== 1) fail('new call not present exactly once after patch');

writeFileSync(target, patched);
